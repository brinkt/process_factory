require 'spec_helper'
require 'test_crack_sha256'

describe TestCrackSHA256 do

  it 'completes a brute force crack using 16 threads' do
    t = TestCrackSHA256.new('t', 16)
    t.factory.run
    expect(t.results).to be_a(Hash)
    expect(t.results[:valid]).to be_a(Fixnum)
  end

  it 'completes a brute force crack using 4 processes' do
    t = TestCrackSHA256.new('p', 4)
    t.factory.run
    expect(t.results).to be_a(Hash)
    expect(t.results[:valid]).to be_a(Fixnum)
  end

end
