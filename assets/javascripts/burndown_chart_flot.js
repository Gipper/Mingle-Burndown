
mingleBurndown = {

  init_Burndown: function (instance){

    // get the data from our instance
    // it's better to use individial data attributes here...we have things like dates that will not translate well.
    var iterationStart = jQuery("#" + instance).data('iterationStart');
    var iterationEnd =  jQuery("#" + instance).data('iterationEnd');
    var actualHours = jQuery("#" + instance).data('actualHours');
    var sampleRate = jQuery("#" + instance).data('sampleRate');

    if (iterationStart && iterationEnd && actualHours){
     
        mingleBurndown.drawBurndown(instance, iterationStart, iterationEnd, actualHours, sampleRate);
        //mingleBurndown.drawBurndown(instance, iterationStart, iterationEnd, actualHours);

     }
    },

    drawBurndown: function (instance, iterationStart, iterationEnd, actualHours, sampleRate){
		// drawBurndown: function (instance, iterationStart, iterationEnd, actualHours){

        // set up the plot values
   
        iterationLength = mingleBurndown.getIterationDays(iterationStart, iterationEnd).length;
        actualData = mingleBurndown.splitMingleData(actualHours);
        actualBurndown = mingleBurndown.createActualBurndown(actualData);
        idealBurndown = mingleBurndown.createIdealBurndown (actualData[0], iterationLength);
        drawToday = "true";
                                                  
        // if we are past the end date, don't draw the today column
  
        if (todayIndex > 0) {
            flotTodayArray = [[todayIndex,actualData[0]]];
            } else {
          flotTodayArray = [[1,0]];
          drawToday = "false";
        }
        
        jQuery.plot(jQuery("#"+ instance),
          [{"bars": {"show": drawToday}, "data":flotTodayArray, "label": "Today"},
           {"lines": {"show": "true", "lineWidth": 1}, "points": {"show": "true"}, "data": idealBurndown, "label": "Ideal Burndown"},
           {"lines": {"show": "true", "lineWidth": 6}, "points": {"show": "true"}, "data": actualBurndown, "label": "Actual Burndown"}],
           {"xaxis": {"ticks": iterationDays}, "legend": {"position": "sw"}, "colors": ["#99ff99", "#999999", "#ff6600"]
        });
     },

     // Private helper functions
    getIterationDays: function (sDate, eDate){
    // Constructs chart tick labels based on start and end dates. (skips weekends)
    // Now with weekly ability.
    
    var now = new Date();
    var startDate = new Date(sDate);
    var endDate = new Date(eDate);
    var deliveryDate = endDate.setDate(endDate.getDate() + 1);
    iterationDay = [];
    iterationDays = [];
    numdays = 1;
    todayIndex = -1;
    
    while (startDate <= deliveryDate) {
      // push current day number and date into ticks array if it is a weekday
      // added 8/20/09: Only count Wednesdays if plotting weekly.
      
      if (sampleRate == "Weekly") {
        if (startDate.getDay() == 3) {
                                              
          // capture today index for drawing today column.
          // must be done here, after this point, date is abbreviated.
          if (startDate <= now) {
            todayIndex = numdays;
          }
                                            
          iterationDay = [numdays++,(startDate.getMonth() + 1) + "/" + startDate.getDate()];
          iterationDays.push(iterationDay);
        }
      }

      // for daily sample rate
      else {
        if (startDate.getDay() % 6 !== 0) {
        
          // capture today index for drawing today column.
          // must be done here, after this point, date is abbreviated.
          if (startDate <= now) {
            todayIndex = numdays;
          }
                                          
          iterationDay = [numdays++,(startDate.getMonth() + 1) + "/" + startDate.getDate()];
          iterationDays.push(iterationDay);
        }
      }
      
      startDate.setDate(startDate.getDate() + 1);
    }
    return iterationDays;
  },
                               
  createIdealBurndown: function(totalHours, iterationLength){
    // Creates ideal burndown array (flot format) based on estimated hours and iteration length
    // format: [[index1, value1],[index2, value2]]
    
    dataPoint = [];
    dataPoints = [];
    avgDailyBurn = totalHours / (iterationLength -1); // accounts for delivery on morning of last day
    
    for (x=0; x<iterationLength; x++) {
      // format for flot
      dataPoint = [x+1, parseInt(totalHours - (avgDailyBurn*x))];
      dataPoints.push(dataPoint);
    }
    return dataPoints;
  },

  splitMingleData: function (actualHours){
    // Process the values of a text field containing the daily burndown hours which are comma separated.
    
    hoursData = [];
    hoursData = actualHours.split(",");
    return hoursData;
  },
  
  createActualBurndown: function (hoursData){
    // Builds flot-formatted data for Actual Burndown values. format: [[index1, value1],[index2, value2]]
    
    actualBurndown = [];
    for (x=0; x<hoursData.length; x++)  {
      actualBurndownDay = [x+1,hoursData[x]];
      actualBurndown.push(actualBurndownDay);
    }
    return actualBurndown;
  }

};

jQuery(document).ready(function(){
  jQuery(".mingleBurndown").each(function(){
    mingleBurndown.init_Burndown(this.id);
  });
});