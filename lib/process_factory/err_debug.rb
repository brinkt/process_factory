class ProcessFactory::ErrDebug
  attr_reader :err
  
  def initialize(e)
    begin 
      Marshal.dump(e)
    rescue
      @err = StandardError.new("Marshal.dump(err) failed: #{e.inspect}")
    end
    @err = e unless @err
  end
end