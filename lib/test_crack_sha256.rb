require 'digest'

class TestCrackSHA256
  attr_reader :factory, :target
  attr_accessor :results

  include ProcessFactory

  #-------------------------------------------------------------------------------------#

  def initialize(mode, count)
    # random number between 1 and 100 million
    @target = Digest::SHA256.hexdigest(rand(100000000).to_s)
    @factory = ProcessFactory::Factory.new(self, {
      mode: mode,
      count: count,
      pre: 'brute_pre',
      worker: 'brute_worker',
      post: 'brute_post'
    })
  end

  #-------------------------------------------------------------------------------------#
  # Mutex.synchronize

  def brute_pre(options)
    return if @results.is_a?(Hash) && @results[:valid]

    # set up @results hash if not yet defined
    @results = { combo: 0, count: 0, last: Time.now.to_i } if !@results.is_a?(Hash)

    # split into chunks of 1 million
    c = Marshal.load(Marshal.dump(@results[:combo]))
    options.merge!({ combo: (c...c+1000000) })
    @results[:combo] += 1000000

    options
  end

  #-------------------------------------------------------------------------------------#
  # expensive: run sha256 on 1 million possible combos

  def brute_worker(options)
    options[:combo].each do |x| 
      return options.merge({ valid: x }) if Digest::SHA256.hexdigest(x.to_s) == @target
    end

    options
  end

  #-------------------------------------------------------------------------------------#
  # Mutex.synchronize

  def brute_post(options)
    return unless options

    @results[:count] += 1000000

    # save & console display if found valid
    if options[:valid]
      @results[:valid] = options[:valid]
      puts "Found valid combo: #{@results[:valid]}"
    end
    
    # console display updates every 5 seconds
    if Time.now.to_i-@results[:last] > 5
      @results[:last] = Time.now.to_i
      puts "Processed: #{@results[:count]} combos!"
    end

    # saved to @results; no need to return anything
  end

  #-------------------------------------------------------------------------------------#
end