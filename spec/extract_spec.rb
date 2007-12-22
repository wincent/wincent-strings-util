#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), 'spec_helper.rb')

describe '-extract functionality' do
  describe 'with missing strings in target' do
    before(:all) do
      @base   = file('english.strings')
      @target = file('spanish_missing.strings')
      @result = Util.run('-base', @base, '-extract', @target)
    end

    it 'should extract the missing strings' do
      @result.stdout.should == File.read(file('spanish_missing_extracted.strings'))
    end
  end

  describe 'with untranslated strings in target' do
    before(:all) do
      @base   = file('english.strings')
      @target = file('spanish_partially_translated.strings')
      @result = Util.run('-base', @base, '-extract', @target)
    end

    it 'should extract the untranslated strings' do
      @result.stdout.should == File.read(file('spanish_untranslated_extracted.strings'))
    end
  end

  describe 'with fully-translated target' do
    before(:all) do
      @base   = file('english.strings')
      @target = file('spanish_fully_translated.strings')
      @result = Util.run('-base', @base, '-extract', @target)
    end

    it 'should extract nothing' do
      @result.stdout.should == File.read(file('empty.strings'))
    end
  end
end