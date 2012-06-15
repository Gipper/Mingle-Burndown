require 'test/unit'
require File.join(File.dirname(__FILE__), '..', '..', 'init.rb')
require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'burndown_chart_flot')
require File.join(File.dirname(__FILE__), 'rest_loader')

class Test::Unit::TestCase

  def project(name)
    @project ||= RESTfulLoaders::ProjectLoader.new(name, nil, self).project
  end  

  def errors
    @errors ||= []
  end  
  
  def alert(message)
    errors << message
  end
end  
