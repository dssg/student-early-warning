/*

This is the JavaScript code to create the time series chart using the 
JavaScript library Highcharts (http://highcharts.com). Most of the code 
simply customizes the chart options

Highcharts API: http://api.highcharts.com/highcharts

High-level summary of the code
	1. specify the default options 
		>> var defaultOptions = { ... };
	2. get data from Shiny 
		>> Shiny.addCustomMessageHandler("newStudents", function(newData) { ... });
	3. draw the chart 
		>> var chartObj = new Highcharts.Chart(newOptions);
	4. create event handlers for mouse events (e.g., clicks, hovers)
		>> clickAction = function() { ... };
		>> $(element).click( function() {  
		>> 		clickAction.call(currentStudent);       
		>> });

Understanding JavaScript and Shiny input/output

	The code both 
		(a) gets data from Shiny 
			>> Shiny.addCustomMessageHandler("newStudents", function(newData) { ... });
		(b) sends data to Shiny on which student ID is currently highlighted.
			>> Shiny.onInputChange("selectID", this.data[0].id);

	This tutorial is super helpful to understand the JavaScript/Shiny integration:
		http://ryouready.wordpress.com/2013/11/20/sending-data-from-client-to-server-and-back-using-shiny/
*/

//jQuery magic
$(document).ready(function () {

  
  //title for x axis. other axis options will be defined at rendering time.
  var xTitle = "Grade";
  
  //specify chart options (but don't create the chart just yet)
  var defaultOptions = {
                           
  //overall chart options
  title: {text: null },
  series: null, //data goes here. initialize as null. will be updated later.
  chart: {
    zoomType: "xy",
    width: 900,
    height: 400,
    renderTo: "highChart"  //where should the chart be rendered on the page?
                           //should correspond to the id of a div HTML tag 
                           //in this case, "highChart" corresponds to this
                           //below line code in ui.R:
                           //     tags$div(id="highChart")
  },
                           
  //doesn't seem like we need the below, but will keep 
  //as a precaution for linking with HTML/shiny
  //maybe not necessary because jQuery handles the input/output? Not sure.
  dom: "highChart",  
  id: "highChart",  
                           
  //get rid off exporting options and Highcharts logo
  exporting: {enabled: true},
  credits: {href: null, text: null},
                           
  //x axis options. these options will be updated later
  xAxis: [{
    title: {
      text: xTitle,
      style: {fontSize: 15 } 
    },
    min: null,  
    max: null 
  }],
                           
  //y axis options. these options will be updated later
  yAxis: [{
    title: {
      text: null,
      style: {fontSize: 15 } 
    },
    min: null,
    max: null,
    allowDecimals: false,
    startOnTick: false,
    endOnTick: false,
    gridLineWidth:  0 
  }],
                           
  //tooltip options
  tooltip: {enabled: false},
  /*tooltip: {
    useHTML: true,
    crosshairs: false,
    followPointer: false,
    hideDelay: 0,
    formatter:  function() { return this.series.name; }  
  },*/
                             
  //legend options
  legend: {
    itemWidth: 150,
    enabled: true,
    layout: "vertical",
    align: "right",
    verticalAlign: "top",
    y:  0,
    title: {
      text: 'Hover to highlight<br/>'
            +'<span style="font-size: 9px; color: #666; font-weight: normal">'
            +'(sorted by risk score)'
            +'</span>' 
    },
    itemStyle: {fontSize: 11 },
    itemHoverStyle: {fontSize: 14 } 
  },
                           
                           
  //other plot options
  plotOptions: {
    series: {
      states: {
        //what should be the width of a line when it is hovered over?
        hover: {
          lineWidth: 6 
        }
      } 
    },
    line: {
      cursor: "pointer",
                               
        //what should be the width of a line normally?
        lineWidth: 2,
                               
        events: {
                                 
          //what should change when clicking and moving over lines?
          click:     function() { clickAction.call(this);       },
          mouseOver: function() { highlightStudent.call(this);  },
          mouseOut:  function() { mouseleaveAction.call(this);  },
                                 
          //prevent the default action of clicking the legend item.
          //use custom jQuery event handlers defined later in the code
          legendItemClick: function (event) {
            event.preventDefault();
          }
        },
                               
        //just show connected lines (not individual points)
        marker: {
          symbol: "circle",
          radius:  0 
        },
                               
        //how long should the tooltip be displayed for?
        tooltip: {
          hideDelay: 0,
          followPointer: false 
        } 
      } 
    }
  };
  
  
  //wait until Shiny has sent data to actually create the chart
  //this Shiny message handler will also re-draw the chart if new data comes in
  Shiny.addCustomMessageHandler("newStudents", function(newData) {
    
    //NOTE: The above "newStudents" syntax corresponds to this below line of code in server.R:
      //  session$sendCustomMessage(type="newStudents",highchartsData())
    
    var newOptions = defaultOptions;
    newOptions.series = newData.series; //update the series data 
    newOptions.xAxis[0].min = newData.xMin;
    newOptions.xAxis[0].max = newData.xMax;
    newOptions.yAxis[0].min = newData.yMin;
    newOptions.yAxis[0].max = newData.yMax;
    newOptions.yAxis[0].title.text = newData.yTitle;
    var chartObj = new Highcharts.Chart(newOptions); //re-draw the Highcharts chart
    
    //this function will set all the students to the background color
    var backColor = "#E0E0E0"
    clearBackground = function() {
      for(i=0; i < chartObj.series.length; i++) {
        chartObj.series[i].graph.attr("stroke",backColor);
      }
    };
    
    //clickedStudent will be an object for the student that has been 
    //most recently clicked
    var clickedStudent = null;
    
    //function used to highlight a specific student
    highlightStudent = function() {
      //if no student is currently clicked, then clear everything
      if (clickedStudent == null) clearBackground();
      this.graph.attr("stroke", this.color); //change color
      this.group.toFront(); //bring to the front
      
      //this will send a value (this.data[0].id = current student ID)
      //to the Shiny server. This value can be accessed as input$selectID
      //in server.R
      Shiny.onInputChange("selectID", this.data[0].id); 
    };
    
    //if a student has been clicked before, then highlight only that student
    //after a mouse hover event. Otherwise, restore to the default display
    mouseleaveAction = function() {
      if (clickedStudent != null) {
        this.graph.attr("stroke", backColor);
        highlightStudent.call(clickedStudent);  
      } else {
        restoreDefault();
      }
    };
    
    //if a student has just been clicked, then highlight only that student
    clickAction = function() {
      clearBackground(); //make all students have the background color
      highlightStudent.call(this); //highlight the clicked student
      clickedStudent = this; //update the clickedStudent object
    };
    
    //restore defaults if the users double clicks on the legend text
    restoreDefault = function() {
      clickedStudent = null;   //"un-click" the clicked student
      for(i=0; i < chartObj.series.length; i++) {
        //restore colors
        chartObj.series[i].graph.attr("stroke",chartObj.series[i].color);
      }
    };
    
    
    //Create custom event handlers for the clicking and hovering 
    //over the legend text
    $('.highcharts-legend-item').each(function(index, element) {
      
      //the object for the student corresponding to the mouse event
      var currentStudent = chartObj.series[index];
      
      //what should change when clicking and moving over the legend text?
      $(element).mouseover(  function() {  highlightStudent.call(currentStudent);  });
      $(element).mouseleave( function() {  mouseleaveAction.call(currentStudent);  });
      $(element).click(      function() {  clickAction.call(currentStudent);       });
      $(element).dblclick(   function() {  restoreDefault()                        });
      
      console.log(element);
    });
    
    Shiny.addCustomMessageHandler("updateVariable", function(newVariable) {
      //check to make sure the chart actually does need to get updated
      if (newVariable.yTitle != chartObj.options.yAxis[0].title.text) {
        
        //reset chart properties (axes and series data)
        chartObj.yAxis[0].setTitle({text: newVariable.yTitle}, false);
        chartObj.yAxis[0].setExtremes(newVariable.yMin,newVariable.yMax, false);
        chartObj.xAxis[0].setExtremes(newVariable.xMin,newVariable.xMax, false);
        for (var i = 0; i < newVariable.series.length; i++) {
          chartObj.series[i].setData(newVariable.series[i].data, false);
        };
        chartObj.redraw();
      }
    });
  });
});



    