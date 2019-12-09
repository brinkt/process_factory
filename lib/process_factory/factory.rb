class ProcessFactory::Factory
  attr_reader :parent, :options, :mutex, :workers

  #-------------------------------------------------------------------------------------#
  # shortcut methods to determine {mode}

  def threads?; true if @options[:mode] == 't'; end
  def processes?; true if @options[:mode] == 'p'; end
  def debug?; true if @options[:mode] == 'd'; end

  #-------------------------------------------------------------------------------------#

  def initialize(parent, options)
    ProcessFactory::Factory.validate_(parent, options)

    @parent = parent
    @options = options
    @mutex = Mutex.new if !debug?

    if processes? # create & fork worker processes
      @workers = Array.new(@options[:count])
      options[:count].times do |i|
        @workers[i] = ProcessFactory::Worker.new(@parent, @options.merge(workers: @workers))
      end
    end
  end

  #-------------------------------------------------------------------------------------#
  # validate options
  
  def self.validate_(parent, options)
    if !options.is_a?(Hash)
      raise 'Options not a hash!'
    else
      raise 'Mode not set!' unless ['t','p','d'].include?(options[:mode])
      raise 'Number of threads invalid!' if !options[:count].is_a?(Fixnum) || options[:count] < 1

      # validate dynamic methods best as possible
      [:pre, :worker, :post].each do |m|
        mt = "#{m[0].upcase+m[1..m.length]}"
        if options[m] && parent.respond_to?(options[m])
          raise "#{mt} method requires 1 argument!" if parent.method(options[m]).arity != 1
        else
          raise "#{mt} method not defined!"
        end
      end
    end
  end

  #-------------------------------------------------------------------------------------#
  # yielding threads

  def threaded(count)
    results = threads = Array.new(count)
    count.times { |t| threads[t] = Thread.new { results[t] = yield(t) } }
    rescue_ctrl_c(threads)
    threads.compact.each do |t|
      begin
        t.join
      rescue Interrupt # thread died
      end
    end
  end

  #-------------------------------------------------------------------------------------#
  # exit on Ctrl+C

  def rescue_ctrl_c(threads)
    Signal.trap :SIGINT do
      if processes?
        @workers.map(&:pid).each do |p|
          begin
            Process.kill(:KILL, p)
          rescue Errno::ESRCH # ignore dead
          end
        end
      elsif threads?
        threads.compact.each { |t| t.kill }
      end
      puts "\nEnding threads/processes..."
      exit
    end
  end

  #-------------------------------------------------------------------------------------#
  # main method to start synchronized calculation

  def run
    exception = nil

    if debug?
      loop do
        break if exception
        begin
          instr = @parent.send(@options[:pre], @options)
          break unless instr.is_a?(Hash)
          @parent.send(@options[:post], @parent.send(@options[:worker], instr))
        rescue Interrupt # ctrl+c
          puts "\nEnding threads/processes..."
          exit
        rescue StandardError => e
          exception = ProcessFactory::ErrDebug.new(e)
        end
      end
    else
      threaded(@options[:count]) do |t|
        begin
          loop do
            break if exception

            begin
              opts = @mutex.synchronize { @parent.send(@options[:pre], @options.merge(thread: t)) }
              break unless opts.is_a?(Hash)

              if processes?
                begin
                  # write/read IO.pipe
                  Marshal.dump(opts, @workers[t].write)
                  opts = Marshal.load(@workers[t].read)
                rescue IOError, Errno::EPIPE # process died
                  # TODO: retry up to 3 times?
                  opts = ProcessFactory::ErrDebug.new("Process #{t} died...")
                end
              elsif threads?
                opts = @parent.send(@options[:worker], opts)
              end

              if opts.is_a?(ProcessFactory::ErrDebug)
                exception = opts
              else
                @mutex.synchronize { @parent.send(@options[:post], opts) }
              end

            rescue StandardError => e
              exception = ProcessFactory::ErrDebug.new(e)
            end

          end
        ensure
          @workers[t].close && @workers[t].wait if processes?
        end
      end
    end

    raise exception if exception
  end

  #-------------------------------------------------------------------------------------#
end