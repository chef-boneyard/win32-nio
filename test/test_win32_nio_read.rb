########################################################################
# test_win32_nio_read.rb
#
# Tests for the NIO.read method.
########################################################################
require 'test-unit'
require 'win32/nio'
include Win32

class TC_Win32_NIO_Read < Test::Unit::TestCase
  def self.startup
    Dir.chdir(File.expand_path(File.dirname(__FILE__)))

    @@file = 'read_test.txt'
    @@text = "The quick brown fox jumped over the lazy dog's back"

    File.open(@@file, 'w'){ |fh|
      100.times{ |n| fh.puts @@text + ": #{n}" }
    }
  end

  def setup
    @size  = File.size(@@file)
  end

  test "version number is set to expected value" do
    assert_equal('0.1.2', Win32::NIO::VERSION)
  end

  test "read method basic functionality" do
    assert_respond_to(NIO, :read)
    assert_nothing_raised{ NIO.read(@@file) }
  end

  test "read method accepts a file name and returns a string of the expected size" do
    assert_kind_of(String, NIO.read(@@file))
    p @size
    p NIO.read(@@file).size
    assert_true(NIO.read(@@file).size == @size)
  end

  test "read method accepts a length argument and returns a string of that length" do
    assert_nothing_raised{ NIO.read(@@file, 19) }
    assert_equal('The quick brown fox', NIO.read(@@file, 19))
    assert_equal('', NIO.read(@@file, 0))
  end

  test "read method accepts an offset and returns a string between offset and length" do
    assert_nothing_raised{ NIO.read(@@file, 19, 4) }
    assert_equal('quick brown fox', NIO.read(@@file, 15, 4))
    assert_equal("lazy dog's back: 99\r\n", NIO.read(@@file, nil, @size-21))
  end

  test "read method requires at least one argument" do
    assert_raise(ArgumentError){ NIO.read }
  end

  test "length parameter must be a positive number" do
    assert_raise(ArgumentError){ NIO.read(@@file, -1) }
    assert_raise(TypeError){ NIO.read(@@file, 'foo') }
  end

  test "offset parameter must be a positive number" do
    assert_raise(Errno::EINVAL, Errno::ENAMETOOLONG){ NIO.read(@@file, 1, -1) }
    assert_raise(TypeError){ NIO.read(@@file, 1, 'foo') }
  end

  test "options parameter must be a hash" do
    assert_raise(TypeError){ NIO.read(@@file, 1, 1, 'foo') }
  end

  def teardown
    @size = nil
  end

  def self.shutdown
    File.delete(@@file) if File.exists?(@@file)
    @@file = nil
    @@text = nil
  end
end
