require 'rubygems'

Gem::Specification.new do |spec|
  spec.name     = 'win32-nio'
  spec.version  = '0.0.3'
  spec.author   = 'Daniel J. Berger'
  spec.license  = 'Artistic 2.0'
  spec.email    = 'djberg96@gmail.com'
  spec.homepage = 'http://www.rubyforge.org/projects/win32utils'
  spec.platform = Gem::Platform::RUBY
  spec.summary  = 'Native IO for MS Windows'
  spec.has_rdoc = true
  spec.files    = Dir['**/*'].reject{ |f| f.include?('git') }

  spec.rubyforge_project = 'Win32Utils'
  spec.extra_rdoc_files  = ['README', 'CHANGES', 'MANIFEST']

  spec.description = <<-EOF
    The win32-nio library implements certain IO methods using native
    Windows function calls rather than using the POSIX compatibility
    layer that MRI typically uses. In addition, some methods provide
    additional event handling capability.
  EOF

  spec.add_dependency('windows-pr', '>= 0.9.5')
  spec.add_dependency('win32-event', '>= 0.5.0')
  spec.add_development_dependency('test-unit', '>= 2.0.3')
end
