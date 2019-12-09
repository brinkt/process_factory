module ProcessFactory

  require "process_factory/err_debug"
  require "process_factory/factory"
  require "process_factory/version"
  require "process_factory/worker"

  def processfactory(options)
    f = ProcessFactory::Factory.new(self, options)
    f.run
  end

end
