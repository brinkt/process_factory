require 'spec_helper'

class PFTest
  attr_accessor :results
  include ProcessFactory

  def pre_method_test_1; return; end
  def pre_method_test_2(options)
    return if @results

    options
  end

  def worker_method_test_1; return; end
  def worker_method_test_2(options); return options; end

  def post_method_test_1; return; end
  def post_method_test_2(options)
    @results = options
  end

end

describe ProcessFactory do
  it 'has a version number' do
    expect(ProcessFactory::VERSION).not_to be nil
  end

  it 'validates options=nil' do
    expect {
      ProcessFactory::Factory.validate_(self,nil)
    }.to raise_error('Options not a hash!')
  end

  it 'validates options={}' do
    expect {
      ProcessFactory::Factory.validate_(self,{})
    }.to raise_error('Mode not set!')
  end

  it 'validates mode=nil' do
    expect {
      ProcessFactory::Factory.validate_(self,{ mode: nil })
    }.to raise_error('Mode not set!')
  end

  it 'validates count=nil' do
    expect {
      ProcessFactory::Factory.validate_(self,{
        mode: 'd', count: nil
      })
    }.to raise_error('Number of threads invalid!')
  end

  it 'validates count=-1' do
    expect {
      ProcessFactory::Factory.validate_(self,{
        mode: 'd', count: -1
      })
    }.to raise_error('Number of threads invalid!')
  end

  it 'validates pre=nil' do
    expect {
      ProcessFactory::Factory.validate_(self,{
        mode: 'd', count: 8, pre: nil
      })
    }.to raise_error('Pre method not defined!')
  end

  it 'validates pre method no options argument' do
    expect {
      ProcessFactory::Factory.validate_(PFTest.new,{
        mode: 'd', count: 8, pre: 'pre_method_test_1'
      })
    }.to raise_error('Pre method requires 1 argument!')
  end

  it 'validates worker=nil' do
    expect {
      ProcessFactory::Factory.validate_(PFTest.new,{
        mode: 'd', count: 8, pre: 'pre_method_test_2', worker: nil
      })
    }.to raise_error('Worker method not defined!')
  end

  it 'validates worker method no options argument' do
    expect {
      ProcessFactory::Factory.validate_(PFTest.new,{
        mode: 'd', count: 8, pre: 'pre_method_test_2', worker: 'worker_method_test_1'
      })
    }.to raise_error('Worker method requires 1 argument!')
  end

  it 'validates post=nil' do
    expect {
      ProcessFactory::Factory.validate_(PFTest.new,{
        mode: 'd', count: 8, pre: 'pre_method_test_2', worker: 'worker_method_test_2', post: nil
      })
    }.to raise_error('Post method not defined!')
  end

  it 'validates post method no options argument' do
    expect {
      ProcessFactory::Factory.validate_(PFTest.new,{
        mode: 'd', count: 8, pre: 'pre_method_test_2', worker: 'worker_method_test_2', post: 'post_method_test_1'
      })
    }.to raise_error('Post method requires 1 argument!')
  end

  it 'simulates most basic process' do
    c = PFTest.new
    c.processfactory({
      mode: 'd', count: 8, pre: 'pre_method_test_2', worker: 'worker_method_test_2', post: 'post_method_test_2',
      extra_data: 'test'
    })
    expect(c.results).to be_a(Hash)
    expect(c.results[:extra_data]).to eq("test")
  end

end
