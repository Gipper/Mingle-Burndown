namespace :test do |ns|

  Rake::TestTask.new(:units) do |t|
    t.libs << "test/unit"
    t.pattern = 'test/unit/*_test.rb'
    t.verbose = true
  end

  Rake::TestTask.new(:integration) do |t|
    t.libs << "test/integration"
    t.pattern = 'test/integration/*_test.rb'
    t.verbose = true
  end

end