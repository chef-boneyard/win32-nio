require 'rake'
require 'rake/clean'
require 'rake/testtask'

CLEAN.include("**/*.gem", "**/*.txt")

namespace 'gem' do
  desc 'Create the win32-nio gem'
  task :create => [:clean] do
    spec = eval(IO.read('win32-nio.gemspec'))
    Gem::Builder.new(spec).build
  end

  desc 'Install the win32-nio gem'
  task :install => [:create] do
    file = Dir['*.gem'].first
    sh "gem install #{file}"
  end
end

desc 'Run the benchmark suite'
task :bench do
  sh "ruby -Ilib benchmarks/win32_nio_benchmarks.rb"
end

namespace :test do
  Rake::TestTask.new(:read) do |t|
    t.verbose = true
    t.warning = true
    t.test_files = FileList['test/test_win32_nio_read.rb']
  end

  Rake::TestTask.new(:readlines) do |t|
    t.verbose = true
    t.warning = true
    t.test_files = FileList['test/test_win32_nio_readlines.rb']
  end

  Rake::TestTask.new(:all) do |t|
    t.verbose = true
    t.warning = true
    t.test_files = FileList['test/test*.rb']
  end
end

task :default => 'test:all'
