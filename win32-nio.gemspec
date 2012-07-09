require 'rubygems'

Gem::Specification.new do |spec|
  spec.name     = 'win32-nio'
  spec.version  = '0.1.0'
  spec.author   = 'Daniel J. Berger'
  spec.license  = 'Artistic 2.0'
  spec.email    = 'djberg96@gmail.com'
  spec.homepage = 'http://www.rubyforge.org/projects/win32utils'
  spec.summary  = 'Native IO for MS Windows'
  spec.files    = Dir['**/*'].reject{ |f| f.include?('git') }

  spec.rubyforge_project = 'Win32Utils'
  spec.extra_rdoc_files  = ['README', 'CHANGES', 'MANIFEST']
  spec.required_ruby_version = '> 1.9.0'

  spec.add_dependency('ffi')
  spec.add_dependency('win32-event', '>= 0.6.0')

  spec.add_development_dependency('test-unit')

  spec.description = <<-EOF
    The win32-nio library implements certain IO methods using native
    Windows function calls rather than using the POSIX compatibility
    layer that MRI typically uses. In addition, some methods provide
    additional event handling capability.
  EOF
end
