#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), 'spec_helper.rb')

describe '--encode with unknown encoding' do
  before(:all) do
    @base = file('english.strings')
    @result = Util.run('--base', @base, '--encode', 'foo')
  end

  it 'should exit with a non-zero status' do
    @result.exitstatus.should_not == 0
  end

  it 'should complain about the encoding' do
    @result.stderr.should =~ /must be UTF-16BE or UTF-16LE/
  end

  it 'should show usage information' do
    @result.stderr.should =~ /Usage/
  end

end

describe '--encode UTF-16BE' do
  before(:all) do
    @base = file('english.strings')
    @expected = file('english_BE.strings')
    @result = Util.run('--base', @base, '--encode', 'UTF-16BE')
  end

  it 'should exit with a zero status' do
    @result.exitstatus.should == 0
  end

  it 'should echo base to standard output in big-endian UTF-16' do
    @result.stdout.should == File.read(@expected)
  end

  it 'should emit nothing to standard error' do
    @result.stderr.should == ''
  end
end

describe '--encode UTF-16LE' do
  before(:all) do
    @base = file('english.strings')
    @expected = file('english_LE.strings')
    @result = Util.run('--base', @base, '--encode', 'UTF-16LE')
  end

  it 'should exit with a zero status' do
    @result.exitstatus.should == 0
  end

  it 'should echo base to standard output in little-endian UTF-16' do
    @result.stdout.should == File.read(@expected)
  end

  it 'should emit nothing to standard error' do
    @result.stderr.should == ''
  end
end
