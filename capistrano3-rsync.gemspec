Gem::Specification.new do |gem|
  gem.name = "capistrano3-rsync"
  gem.version = "0.3.0"
  gem.homepage = "http://gitlab.dev.playnext.co.jp/takayasu.oyama/capistrano3-rsync"
  gem.summary = "Deploy with Capistrano using Rsync."
  gem.description = ""

  gem.author = "Takayasu Oyama"
  gem.email = "takayasu.oyama@playnext.co.jp"
  gem.license = "MIT"

  gem.files = `git ls-files`.split($/)
  gem.executables = gem.files.grep(/^bin\//).map(&File.method(:basename))
  gem.test_files = gem.files.grep(/^spec\//)
  gem.require_paths = ["lib"]

  gem.add_dependency "capistrano", "~> 3.2"
end