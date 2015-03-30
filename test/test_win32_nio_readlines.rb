#######################################################################
# test_win32_nio_readlines.rb
#
# Test case for the Win32::NIO.readlines method.
#######################################################################
require 'test-unit'
require 'win32/nio'
require 'win32/event'
include Win32

class TC_Win32_NIO_Readlines < Test::Unit::TestCase
  def self.startup
    @@line = "The quick brown fox jumped over the lazy dog's back"
    @@file = "readlines_test.txt"
    @@size = 10

    File.open(@@file, 'w'){ |fh|
      1.upto(@@size){ |n|
        fh.puts @@line + ": #{n}"
        fh.puts if n % 3 == 0
      }
    }
  end

  def setup
    @array = nil
    @event = Win32::Event.new
  end

  test "readlines method basic functionality" do
    assert_respond_to(NIO, :readlines)
    assert_nothing_raised{ NIO.readlines(@@file) }
  end

  test "readlines returns an array" do
    assert_kind_of(Array, NIO.readlines(@@file))
  end

  test "readlines returns an array of the expected size" do
    assert_equal(@@size + 3, NIO.readlines(@@file).size)
    assert_equal(@@line + ': 1', NIO.readlines(@@file).first)
  end

  test "readlines treats an empty second argument as a paragraph separator" do
    assert_nothing_raised{ NIO.readlines(@@file, '') }
    assert_kind_of(Array, NIO.readlines(@@file, ''))
    assert_equal(4, NIO.readlines(@@file, '').size)
  end

  test "readlines accepts an event object" do
    assert_false(@event.signaled?)
    assert_nothing_raised{ NIO.readlines(@@file, nil, @event) }
    assert_true(@event.signaled?)
  end

  test "readlines expects at least one argument" do
    assert_raise(ArgumentError){ NIO.readlines }
  end

  test "readlines accepts a maximum of three arguments" do
    assert_raise(ArgumentError){ NIO.readlines(@@file, '', @event, true) }
  end

  def teardown
    @array = nil
    @event = nil
  end

  def self.shutdown
    File.delete(@@file) if File.exist?(@@file)
    @@file = nil
    @@size = nil
    @@line = nil
  end
end
