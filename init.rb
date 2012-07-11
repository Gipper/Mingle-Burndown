begin
  require 'macro_development_toolkit'
rescue LoadError
  require 'rubygems'
  require 'macro_development_toolkit'
end

if defined?(RAILS_ENV) && RAILS_ENV == 'production' && defined?(MinglePlugins)
  MinglePlugins::Macros.register(BurndownChartFlot, 'burndown_chart_flot')
end 

require 'fileutils'

module InitUtils
  def InitUtils.deploy_public_files(macro)
    deploy_dir = 'public/plugin_assets/'+macro
    FileUtils.mkpath 'public/plugin_assets'
    FileUtils.rm_r deploy_dir if File.exists? deploy_dir
    FileUtils.cp_r 'vendor/plugins/'+macro+'/assets', deploy_dir
  end
end

InitUtils.deploy_public_files 'burndown_chart_flot'
