class ProcessFactory::Worker
  attr_reader :read, :write, :pid

  #-------------------------------------------------------------------------------------#

  def initialize(parent, options)
    cr, @write = IO.pipe
    @read, cw = IO.pipe

    @pid = Process.fork do
      begin
        options.delete(:workers).each{ |w| w.close if w }
        @write.close; @read.close
        
        while !cr.eof?
          i = Marshal.load(cr)
          begin
            r = parent.send(i[:worker], i)
          rescue StandardError => e
            r = ProcessFactory::ErrDebug.new(e)
          end
          Marshal.dump(r, cw)
        end
      rescue Interrupt
      ensure
        cr.close; cw.close
      end
    end
    cr.close; cw.close
  end

  #-------------------------------------------------------------------------------------#

  def close
    @read.close
    @write.close
  end

  #-------------------------------------------------------------------------------------#

  def wait
    begin
      Process.wait(@pid)
    rescue Interrupt # process died
    end
  end

  #-------------------------------------------------------------------------------------#
end