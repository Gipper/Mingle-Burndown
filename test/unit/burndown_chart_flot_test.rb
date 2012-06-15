require File.join(File.dirname(__FILE__), 'unit_test_helper')

class BurndownChartFlotTest < Test::Unit::TestCase
  
  FIXTURE = 'sample'
  
  def test_macro_contents
    burndown_chart_flot = BurndownChartFlot.new(nil, project(FIXTURE), nil)
    result = burndown_chart_flot.execute
    assert result
  end

end