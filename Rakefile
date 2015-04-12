require 'rake'
require 'rake/clean'
require 'rake/testtask'
include RbConfig

CLEAN.include(
  '**/*.gem',               # Gem files
  '**/*.txt',               # Benchmark files
  '**/*.rbc',               # Rubinius
  '**/*.o',                 # C object file
  '**/*.log',               # Ruby extension build log
  '**/Makefile',            # C Makefile
  '**/*.def',               # Definition files
  '**/*.exp',
  '**/*.lib',
  '**/*.pdb',
  '**/*.obj',
  '**/*.stackdump',         # Junk that can happen on Windows
  "**/*.#{CONFIG['DLEXT']}" # C shared object
)

desc "Build the win32-nio library"
task :build => [:clean] do
  if RbConfig::CONFIG['host_os'] =~ /mingw|cygwn/i
    require 'devkit'
    make_cmd = "make"
  else
    make_cmd = "nmake"
  end
  Dir.chdir('ext') do
    ruby "extconf.rb"
    sh make_cmd
    cp 'nio.so', 'win32' # For testing
  end
end

namespace 'gem' do
  desc 'Create the win32-nio gem'
  task :create => [:clean] do
    require 'rubygems/package'
    spec = eval(IO.read('win32-nio.gemspec'))
    Gem::Package.build(spec)
  end

  desc 'Install the win32-nio gem'
  task :install => [:create] do
    file = Dir['*.gem'].first
    sh "gem install #{file}"
  end
end

desc 'Run the benchmark suite'
task :bench => [:build] do
  sh "ruby -Iext benchmarks/win32_nio_benchmarks.rb"
end

namespace :test do
  Rake::TestTask.new(:read) do |t|
    task :read => [:build]
    t.libs << 'ext'
    t.verbose = true
    t.warning = true
    t.test_files = FileList['test/test_win32_nio_read.rb']
  end

  Rake::TestTask.new(:readlines) do |t|
    task :readlines => [:build]
    t.libs << 'ext'
    t.verbose = true
    t.warning = true
    t.test_files = FileList['test/test_win32_nio_readlines.rb']
  end

  Rake::TestTask.new(:all) do |t|
    task :all => [:build]
    t.libs << 'ext'
    t.verbose = true
    t.warning = true
    t.test_files = FileList['test/test*.rb']
  end
end

task :default => 'test:all'
