#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), 'spec_helper.rb')

describe '-base functionality' do
  before(:all) do
    @base = file('english.strings')
    @result = Util.run('-base', @base)
  end

  it 'should exit with a zero status' do
    @result.exitstatus.should == 0
  end

  it 'should echo base to standard output' do
    @result.stdout.normalize.should == File.read(@base).normalize
  end

  it 'should emit nothing to standard error' do
    @result.stderr.should == ''
  end

  describe 'with -output' do
    it 'should write to output file' do
      @base   = file('english.strings')
      @output = trash('out')
      Util.run('-base', @base, '-output', @output)
      File.read(@output).normalize == File.read(@base).normalize
    end

    it 'should be able to overwrite output file' do
      @base   = trash('out')
      @output = trash('out')
      Util.run('-base', @base, '-output', @output)
      File.read(@output).normalize == File.read(@base).normalize
    end
  end

  describe 'Little-Endian input file with BOM' do
    before(:all) do
      @base = file('english_LE.strings')
      @result = Util.run('-base', @base)
    end

    it 'should exit with a zero status' do
      @result.exitstatus.should == 0
    end

    it 'should echo base to standard output' do
      @result.stdout.normalize.should == File.read(@base).normalize
    end

    it 'should emit nothing to standard error' do
      @result.stderr.should == ''
    end
  end

  describe 'Little-Endian input file without BOM' do
    before(:all) do
      @base = file('english_BOMLESS_LE.strings')
      @result = Util.run('-base', @base)
    end

    it 'should complain about missing BOM' do
      @result.stderr.should =~ /no BOM found/
    end
  end

  describe 'Big-Endian input file with BOM' do
    before(:all) do
      @base = file('english_BE.strings')
      @result = Util.run('-base', @base)
    end

    it 'should exit with a zero status' do
      @result.exitstatus.should == 0
    end

    it 'should echo base to standard output' do
      @result.stdout.normalize.should == File.read(@base).normalize
    end

    it 'should emit nothing to standard error' do
      @result.stderr.should == ''
    end
  end

  describe 'Big-Endian input file without BOM' do
    before(:all) do
      @base = file('english_BOMLESS_BE.strings')
      @result = Util.run('-base', @base)
    end

    it 'should complain about missing BOM' do
      @result.stderr.should =~ /no BOM found/
    end
  end

  describe 'UTF-8 input file with BOM' do
    before(:all) do
      @base = file('english_UTF8.strings')
      @result = Util.run('-base', @base)
    end

    it 'should complain about missing BOM' do
      @result.stderr.should =~ /UTF-8 BOM found/
    end
  end

  describe 'one-byte input file' do
    before(:all) do
      @base = file('one_byte.strings')
      @result = Util.run('-base', @base)
    end

    it 'should complain about file length' do
      @result.stderr.should =~ /too short/
    end
  end

  describe 'two-byte input file' do
    before(:all) do
      @base = file('two_byte.strings')
      @result = Util.run('-base', @base)
    end

    it 'should complain about file length' do
      @result.stderr.should =~ /too short/
    end
  end

  describe 'unreadable or non-existent input file' do
    before(:all) do
      @base = file('one_byte.strings')
      @result = Util.run('-base', @base)
    end

    it 'should complain about unreadability' do
      @result.stderr.should =~ /unreadable/
    end
  end
end
