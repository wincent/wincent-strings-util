#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), 'spec_helper.rb')

describe 'no command line switches' do
  before(:all) do
    @result = Util.run
  end

  it 'should exit with a non-zero status' do
    @result.exitstatus.should_not == 0
  end

  it 'should show usage information' do
    @result.stderr.should =~ /Usage/
  end

  it 'should show legal information' do
    @result.stderr.should =~ /Copyright/
  end
end

describe 'missing command line switches' do
  describe '--info without --strings' do
    before(:all) do
      @result = Util.run('--info', 'foo')
    end

    it 'should exit with a non-zero status' do
      @result.exitstatus.should_not == 0
    end

    it 'should show usage information' do
      @result.stderr.should =~ /Usage/
    end

    it 'should complain about missing --strings switch' do
      @result.stderr.should =~ /--strings option is required/
    end
  end

  describe '--strings without --info' do
    before(:all) do
      @result = Util.run('--strings', 'foo')
    end

    it 'should exit with a non-zero status' do
      @result.exitstatus.should_not == 0
    end

    it 'should show usage information' do
      @result.stderr.should =~ /Usage/
    end

    it 'should complain about missing --strings switch' do
      @result.stderr.should =~ /--info option is required/
    end
  end
end

describe 'conflicting command line switches' do
  describe '--merge and --info' do
    before(:all) do
      @result = Util.run('--merge', 'foo', '--info', 'bar')
    end

    it 'should exit with a non-zero status' do
      @result.exitstatus.should_not == 0
    end

    it 'should show usage information' do
      @result.stderr.should =~ /Usage/
    end

  end

  describe '--merge and -strings' do
    before(:all) do
      @result = Util.run('--merge', 'foo', '--info', 'bar')
    end

    it 'should exit with a non-zero status' do
      @result.exitstatus.should_not == 0
    end

    it 'should show usage information' do
      @result.stderr.should =~ /Usage/
    end
  end
end

