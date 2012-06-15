require 'test/unit'
require File.join(File.dirname(__FILE__), '..', '..', 'init.rb')
require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'burndown_chart_flot')
require File.join(File.dirname(__FILE__), 'fixture_loader')

class Test::Unit::TestCase
  
  def project(name)
    @project ||= FixtureLoaders::ProjectLoader.new(name).project
  end  
   
end