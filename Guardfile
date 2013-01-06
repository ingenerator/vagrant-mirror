guard 'rspec' do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/vagrant-mirror/(.+)\.rb$})     { |m| "spec/vagrant-mirror/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec" }
end