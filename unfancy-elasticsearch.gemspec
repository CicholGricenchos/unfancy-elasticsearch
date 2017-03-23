Gem::Specification.new do |spec|
  spec.name = 'unfancy-elasticsearch'
  spec.version = '0.0.1'
  spec.author = 'cichol'
  spec.summary = 'unfancy elasticsearch mixins for active_record'
  spec.files = Dir.glob("lib/**/*.rb")

  spec.add_dependency 'elasticsearch'

end