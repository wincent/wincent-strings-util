#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), 'spec_helper.rb')

describe '--info functionality' do
  describe 'with no substitutions' do
    before(:all) do
      @plist    = file('Info.plist')
      @strings  = file('no_substitution.strings')
      @result   = Util.run('--info', @plist, '--strings', @strings)
    end

    it 'should exit with a zero status' do
      @result.exitstatus.should == 0
    end

    it 'should pass through file unchanged' do
      @result.stdout.should == File.read(@strings)
    end

    it 'should emit nothing to standard error' do
      @result.stderr.should == ''
    end
  end

  describe 'with substitutions from the property list' do
    before(:all) do
      @plist    = file('Info.plist')
      @strings  = file('plist_substitution.strings')
      @result   = Util.run('--info', @plist, '--strings', @strings)
    end

    it 'should exit with a zero status' do
      @result.exitstatus.should == 0
    end

    it 'should pass through with substitutions' do
      @result.stdout.should == File.read(file('plist_substituted.strings'))
    end

    it 'should emit nothing to standard error' do
      @result.stderr.should == ''
    end
  end

  describe 'with top-level recursion' do
    before(:all) do
      @plist    = file('Info.plist')
      @strings  = file('top_level_recursion.strings')
      @result   = Util.run('--info', @plist, '--strings', @strings)
    end

    it 'should exit with a zero status' do
      @result.exitstatus.should == 0
    end

    it 'should pass through with substitutions' do
      @result.stdout.should == File.read(file('top_level_recursion_substituted.strings'))
    end

    it 'should emit nothing to standard error' do
      @result.stderr.should == ''
    end
  end

  describe 'with multi-level recursion' do
    before(:all) do
      @plist    = file('Info.plist')
      @strings  = file('multi_level_recursion.strings')
      @result   = Util.run('--info', @plist, '--strings', @strings)
    end

    it 'should exit with a zero status' do
      @result.exitstatus.should == 0
    end

    it 'should pass through with substitutions' do
      @result.stdout.should == File.read(file('multi_level_recursion_substituted.strings'))
    end

    it 'should emit nothing to standard error' do
      @result.stderr.should == ''
    end
  end

  describe 'with direct infinite recursion' do
    before(:all) do
      @plist    = file('Info.plist')
      @strings  = file('direct_infinite_recursion.strings')
      @result   = Util.run('--info', @plist, '--strings', @strings)
    end

    it 'should exit with a non-zero status' do
      @result.exitstatus.should_not == 0
    end

    it 'should complain about infinite recursion' do
      @result.stderr.should =~ /infinite recursion.+CFBundleShortVersionString/
    end
  end

  describe 'with indirect infinite recursion' do
    before(:all) do
      @plist    = file('Info.plist')
      @strings  = file('indirect_infinite_recursion.strings')
      @result   = Util.run('--info', @plist, '--strings', @strings)
    end

    it 'should exit with a non-zero status' do
      @result.exitstatus.should_not == 0
    end

    it 'should complain about infinite recursion' do
      @result.stderr.should =~ /infinite recursion.+CFBundleShortVersionString/
    end
  end

  # repeated values shouldn't trigger the infinite recursion warnings
  describe 'with repeated values' do
    before(:all) do
      @plist    = file('Info.plist')
      @strings  = file('repeated_substitution.strings')
      @result   = Util.run('--info', @plist, '--strings', @strings)
    end

    it 'should exit with a zero status' do
      @result.exitstatus.should == 0
    end

    it 'should pass through with substitutions' do
      @result.stdout.should == File.read(file('repeated_substituted.strings'))
    end

    it 'should emit nothing to standard error' do
      @result.stderr.should == ''
    end
  end

  describe 'with missing substitutions' do
    before(:all) do
      @plist    = file('Info.plist')
      @strings  = file('missing_substitution.strings')
      @result   = Util.run('--info', @plist, '--strings', @strings)
    end

    it 'should exit with a non-zero status' do
      @result.exitstatus.should_not == 0
    end

    it 'should complain about missing value' do
      @result.stderr.should =~ /no value found.+NSFunnyKey/
    end
  end

end
