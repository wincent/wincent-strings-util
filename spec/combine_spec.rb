#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), 'spec_helper.rb')

describe '--combine functionality' do
  describe 'with no overlap between the two files' do
    before(:all) do
      @base   = file('spanish_missing.strings')
      @target = file('spanish_missing_translated.strings')
      @result = Util.run('--base', @base, '--combine', @target)
    end

    it 'should combine the two files' do
      @result.stdout.should == File.read(file('spanish_fully_translated.strings'))
    end

    it 'should issue no messages on the standard error' do
      @result.stderr.should == ''
    end
  end

  describe 'with some overlap between the two files' do
    before(:all) do
      @base   = file('spanish_partially_translated.strings')
      @target = file('spanish_missing_translated.strings')
      @result = Util.run('--base', @base, '--combine', @target)
    end

    it 'should combine the two files' do
      @result.stdout.should == File.read(file('spanish_fully_translated.strings'))
    end

    it 'should warn about overwriting' do
      @result.stderr.should =~ /both files.+will overwrite base/
    end
  end
end