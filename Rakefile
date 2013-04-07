#!/usr/bin/env rake
require 'rubygems'
require 'bundler/setup'
require 'rspec/core/rake_task'

# Change to the directory of this file.
Dir.chdir(File.expand_path("../", __FILE__))

# This installs the tasks that help with gem creation and
# publishing.
Bundler::GemHelper.install_tasks

desc "Open an irb session preloaded with vagrant-mirror"
task :console do
  sh "irb -rubygems -I lib -r vagrant-mirror"
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new do |t|
  t.pattern = "spec/**/*_spec.rb"
end

# From the vagrant-notify gem
desc 'Outpus some information about Vagrant middleware stack useful for development (use ACTION=action_name to filter out actions)'
task 'vagrant-stack' do
  require 'vagrant'
  Vagrant.actions.to_hash.each do |action, stack|
    next unless !ENV['ACTION'] || ENV['ACTION'] == action.to_s

    puts action
    stack.send(:stack).each do |middleware|
      puts "  #{middleware[0]}"
      puts "    -> #{middleware[1].inspect}" unless middleware[1].empty?
    end
  end
end

task :default => :spec