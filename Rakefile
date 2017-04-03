require 'rspec/core/rake_task'
require 'foodcritic'

desc 'Run unit tests'
RSpec::Core::RakeTask.new(:spec)

desc 'Run style checks'
FoodCritic::Rake::LintTask.new(:style)
