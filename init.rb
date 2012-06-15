begin
  require 'macro_development_toolkit'
rescue LoadError
  require 'rubygems'
  require 'macro_development_toolkit'
end

if defined?(RAILS_ENV) && RAILS_ENV == 'production' && defined?(MinglePlugins)
  MinglePlugins::Macros.register(BurndownChartFlot, 'burndown_chart_flot')
end 