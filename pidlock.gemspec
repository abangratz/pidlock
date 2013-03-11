Gem::Specification.new do |s|
  s.name = 'pidlock'
  s.version = '0.2.0'
  s.date = "2013-03-04"
  s.summary = "Using PID/file locking for daemons and long running tasks made easy."
  s.description = "Used for locking processes via PID and file (daemon style)."
  s.authors = ["Anton Bangratz"]
  s.email = "anton.bangratz@gmail.com"
  s.files = Dir['lib/*.rb'] + Dir['spec/**/*.rb']
  s.homepage = 'https://github.com/abangratz/pidlock'
  s.add_runtime_dependency 'sys-proctable', '~>0.9.2'
  s.extra_rdoc_files = ['README.mkd']
end
