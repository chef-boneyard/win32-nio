require 'rubygems'
gem 'test-unit'

require 'win32/nio'
require 'test/unit'
include Win32

class TC_Win32_NIO_Read < Test::Unit::TestCase
   def self.startup
      Dir.chdir(File.expand_path(File.dirname(__FILE__)))

      @@file = 'read_test.txt'
      @@text = "The quick brown fox jumped over the lazy dog's back"

      File.open(@@file, 'w'){ |fh|
         100.times{ |n|
            fh.puts @@text + ": #{n}"
         }
      }
   end

   def setup
      @size  = File.size(@@file)
      @event = Win32::Event.new('test')
   end

   def test_nio_version
      assert_equal('0.0.3', Win32::NIO::VERSION)
   end

   def test_nio_read_basic
      assert_respond_to(NIO, :read)
   end

   def test_nio_read_with_file_name
      assert_nothing_raised{ NIO.read(@@file) }
      assert_kind_of(String, NIO.read(@@file))
      assert_true(NIO.read(@@file).size == @size)
   end

   def test_nio_read_with_file_name_and_length
      assert_nothing_raised{ NIO.read(@@file, 19) }
      assert_equal('The quick brown fox', NIO.read(@@file, 19))
      assert_equal('', NIO.read(@@file, 0))
   end

   def test_nio_read_with_file_name_and_length_and_offset
      assert_nothing_raised{ NIO.read(@@file, 19, 4) }
      assert_equal('quick brown fox', NIO.read(@@file, 15, 4))
      assert_equal("lazy dog's back: 99\r\n", NIO.read(@@file, nil, @size-21))
   end

   def test_nio_read_with_event
      assert_false(@event.signaled?)
      assert_nothing_raised{ NIO.read(@@file, 9, 0, @event) }
      assert_true(@event.signaled?)
   end

   def test_nio_read_expected_errors
      assert_raise(ArgumentError){ NIO.read }
      assert_raise(ArgumentError){ NIO.read(@@file, -1) }
      assert_raise(TypeError){ NIO.read(@@file, 'foo') }
      assert_raise(ArgumentError){ NIO.read(@@file, 1, -1) }
      assert_raise(TypeError){ NIO.read(@@file, 1, 'foo') }
      assert_raise(TypeError){ NIO.read(@@file, 1, 1, 'foo') }
   end

   def test_readlines_basic
      assert_respond_to(NIO, :readlines)
      assert_nothing_raised{ NIO.readlines(@@file) }
      assert_kind_of(Array, NIO.readlines(@@file))
   end

   def test_readlines
      assert_equal("#{@@text}: 0", NIO.readlines(@@file).first)
      assert_equal("#{@@text}: 99", NIO.readlines(@@file).last)
   end

   def teardown
      @size = nil
      @event.close if @event
      @event = nil
   end

   def self.shutdown
      File.delete(@@file) if File.exists?(@@file)
      @@file = nil
      @@text = nil
   end
end
