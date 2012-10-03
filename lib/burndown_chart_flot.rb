class BurndownChartFlot

  def initialize(parameters, project, current_user)
    @parameters = parameters
    @project = project
    @current_user = current_user
  end

  def formatDate (date)    
    # d.gipp: convert to date format expected by flot
    strDate = date[0] + ""
    year, month, day = strDate.split(/-/)
    year + "/" + month + "/" + day
 end
 
    
  def execute

    getIterationStart = @parameters['Iteration_Start']
    getIterationEnd = @parameters['Iteration_End']
    getActualHours = @parameters['Actual_Hours']
    
    # sampleRate = daily or weekly
    sample_rate = @parameters['Sample_Rate']
    target_Instance = @parameters['Target']


    if getIterationStart.nil? or getIterationEnd.nil? or getActualHours.nil?

        printError = "Iteration_Start, Iteration_End, and Actual_Hours are required."

    else
      #set working values based on incoming queries.
      iteration_start = formatDate(@project.execute_mql(getIterationStart).first.values)
      iteration_end = formatDate(@project.execute_mql(getIterationEnd).first.values)
      actual_hours = @project.execute_mql(getActualHours).first.values
    end

    # randID = 1 + rand(900)
    burndownInstance = "mingleBurndown#{target_Instance}" 


  <<-HTML
    <h2>Daily Burndown</h2>
    <div class="mingleBurndown" id="#{burndownInstance}" style="width:600px;height:300px;" data-iterationStart= "#{iteration_start}" data-iterationEnd="#{iteration_end}" data-actualHours="#{actual_hours}" data-sampleRate="#{sample_rate}"></div>
    <script language="javascript" type="text/javascript" src="../../../../plugin_assets/burndown_chart_flot/javascripts/jquery.min.js"></script>
    <script language="javascript" type="text/javascript" src="../../../../plugin_assets/burndown_chart_flot/javascripts/jquery.flot.min.js"></script>
    <script language="javascript" type="text/javascript" src="../../../../plugin_assets/burndown_chart_flot/javascripts/burndown_chart_flot.js"></script>
    
  HTML
  
  end
 
  def can_be_cached?
    false  # if appropriate, switch to true once you move your macro to production
  end
    
end

