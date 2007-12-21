def try_require gem
  begin
    require gem
  rescue LoadError => e
    begin
      require 'rubygems'
      require gem
    rescue LoadError => e
      return false
    end
  end
  return true
end

if not try_require 'spec'
  puts <<-EOF
These specs require RSpec to run.
For more information on RSpec visit:
  http://rspec.info/
To install RSpec:
  sudo gem install rspec
EOF
  exit 1
elsif not try_require 'wopen3'
  puts <<-EOF
These specs require Wopen3 to run.
For more information on RSpec visit:
  http://wincent.com/a/products/walrus/wopen3/
To install Wopen3:
  sudo gem install wopen3
EOF
  exit 1
elsif not try_require 'iconv'
  puts 'These specs require iconv to run.'
  exit 1
end

# Convenience method for providing the full path to file in same directory as this helper.
def file name
  File.join(File.dirname(__FILE__), name)
end

# Convenience method for providing the full path to a file in the spec/trash/ directory.
def trash name
  File.join(File.dirname(__FILE__), 'trash', name)
end

class String
  # In order to make the tests pass on little-endian and big-endian machines, must "normalize" strings before comparing them.
  def normalize
    Iconv.iconv('UTF-16LE', 'UTF-16', self).first
  end
end

# Convenience wrapper for spawning a wincent-strings-util process, capturing standard output, standard error, and the exit status.
class Util
  attr_reader :stdout, :stderr, :exitstatus
  @@path = nil

  def self.path=(custom)
    @@path = custom
  end

  def self.path
    @@path || 'wincent-strings-util'
  end

  def self.run *args
    util = Util.new(args)
    util.run
    util
  end

  def initialize args
    @args       = args
    @stdout     = ''
    @stderr     = ''
    @exitstatus = nil
  end

  def run
    Wopen3.popen3(Util.path, *@args) do |stdin, stdout, stderr|
      threads = []
      threads << Thread.new(stdout) do |out|
        out.each { |line| @stdout << line }
      end
      threads << Thread.new(stderr) do |err|
        err.each { |line| @stderr << line }
      end
      threads.each { |thread| thread.join }
    end
    @exitstatus = $?.exitstatus
  end

end # class Util

Spec::Runner.configure do |config|
  config.after(:all) do
    # clean out trash directory after each describe block
    trashdir = File.join(File.dirname(__FILE__), 'trash')
    Dir.foreach(trashdir) do |item|
      unless item =~ /\A\./
        File.delete File.join(trashdir, item)
      end
    end
  end
end

# Can override the path to wincent-strings-util from the command line in order to test different versions.
if ARGV[0]
  Util.path = ARGV[0]
end

# temp testing only: normally you would do this from within Xcode
Util.path = '/Users/wincent/trabajo/leopard/build/Release/wincent-strings-util'
