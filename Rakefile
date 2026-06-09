require 'bundler/gem_tasks'
require 'minitest/test_task'

Minitest::TestTask.create(:test) do |task|
  task.libs << 'test'
  task.test_globs = ['test/**/*_test.rb']
end

task default: :test
