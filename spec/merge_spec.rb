#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), 'spec_helper.rb')

describe '--merge functionality' do
  describe 'with untranslated target' do
    before(:all) do
      @base   = file('english_augmented.strings')
      @target = file('spanish_untranslated.strings')
      @result = Util.run('--base', @base, '--merge', @target)
    end

    it 'should match base' do
      @result.stdout.normalize.should == File.read(@base).normalize
    end
  end

  describe 'with partially-translated target' do
    before(:all) do
      @base   = file('english_augmented.strings')
      @target = file('spanish_partially_translated.strings')
      @result = Util.run('--base', @base, '--merge', @target)
    end

    it 'should match the base, incorporating the already translated portion' do
      @result.stdout.normalize.should == File.read(file('spanish_partially_translated_merged.strings')).normalize
    end
  end

  describe 'with fully-translated target' do
    before(:all) do
      @base   = file('english_augmented.strings')
      @target = file('spanish_fully_translated.strings')
      @result = Util.run('--base', @base, '--merge', @target)
    end

    it 'should match the base, incorporating the already translated portion' do
      @result.stdout.normalize.should == File.read(file('spanish_fully_translated_merged.strings')).normalize
    end
  end
end
