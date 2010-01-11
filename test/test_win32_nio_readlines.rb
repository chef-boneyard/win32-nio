#######################################################################
# test_win32_nio_readlines.rb
#
# Test case for the Win32::NIO.readlines method.
#######################################################################
require 'rubygems'
gem 'test-unit'
require 'test/unit'
require 'win32/nio'
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
   end

   def test_nio_readlines_basic
      assert_respond_to(NIO, :readlines)
   end

   def test_nio_readlines
      assert_nothing_raised{ NIO.readlines(@@file) }
      assert_kind_of(Array, NIO.readlines(@@file))
      assert_equal(@@size + 3, NIO.readlines(@@file).size)
      assert_equal(@@line + ': 1', NIO.readlines(@@file).first)
   end

   def test_nio_readlines_with_empty_line_ending
      assert_nothing_raised{ NIO.readlines(@@file, '') }
      assert_kind_of(Array, NIO.readlines(@@file, ''))
      assert_equal(4, NIO.readlines(@@file, '').size)
   end

   def test_nio_readlines_expected_errors
      assert_raise(ArgumentError){ NIO.readlines }
      assert_raise(ArgumentError){ NIO.readlines(@@file, '', true) }
   end

   def teardown
      @array = nil
   end

   def self.shutdown
      File.delete(@@file) if File.exists?(@@file)
      @@file = nil
      @@size = nil
      @@line = nil
   end
end
