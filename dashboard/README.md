## Overview 

View a working demo of the student dashboard [here](http://d-miller.shinyapps.io/RiskVizDemo/). The code for the dashboard integrates the strengths of R for data analysis and JavaScript for interactivity. 

![Dashboard](http://i.imgur.com/050QiW1.png)

The [Shiny](http://shiny.rstudio.com/) package, written in R, can...
* Run R code on a Shiny server (e.g., http://www.shinyapps.io) 
* Read data from various sources including [databases](http://www.r-bloggers.com/mysql-and-r/), [user-uploaded data](http://shiny.rstudio.com/gallery/file-upload.html), and data stored on the Shiny server.
* Process data using any R function or package (e.g., to generate predictions from a [random forest model](http://cran.r-project.org/web/packages/randomForest/index.html))
* Send processed data to other web-based platforms (e.g., based on HTML/JavaScript)

JavaScript can...
* Generate interactive visualizations using libraries such as [D3](http://d3js.org/) and [HighCharts](http://www.highcharts.com/). Our example uses HighCharts, which is free for non-commercial use.
* Create custom event handlers using the [jQuery](http://jquery.com/) library for determining actions of mouse clicks, hovers, etc.
* Request Shiny to send more data, do more analyses, etc. 

## Language integration

The below diagram shows how the different code components talk to each other. The server.R and ui.R are standard files to include for any Shiny app. The server.R code runs the core data processing in R using the Shiny server, whereas ui.R specifies how the output should be displayed to the user. 

![integration](http://i.imgur.com/kIFM7Ru.png)

The JavaScript chart.js code, server.R R code, and ui.R/HTML code can all talk to each other. Below are some code snippets on how this communication is implemented.

* server.R -> chart.js 
 1. server.R code: `observe({ session$sendCustomMessage(type="newStudents", data })`
 2. chart.js code: `Shiny.addCustomMessageHandler("newStudents", function(newData) { ... });`

* chart.js -> server.R
 1. chart.js: `Shiny.onInputChange("selectID", this.data[0].id);`
 2. server.R: `currentStudent <- input$selectID`

* chart.js -> ui.R (using HighCharts)
  1. chart.js: `var chartObj = new Highcharts.Chart({chart: {renderTo: "highChart", ...}, ... });`
  2. ui.R: `tags$div(id="highChart")`

* ui.R/HTML -> chart.js (using jQuery)
  1. ui.R/HTML: (chart.js creates relevant HTML code containing elements of class highcharts-legend-item).
  2. chart.js: `$('.highcharts-legend-item').each(function(index, element) { ... });`

Communication between server.R and ui.R is part of Shiny's standard functionality (tutorial [here](http://shiny.rstudio.com/tutorial/)). One non-standard application was to use the renderUI function to create HTML text in server.R and htmlOutput in ui.R to display that HTML code for the student report card.
 1. server.R: `output$reportCard <- renderUI({  return(createReportCard(currentData)) })`
 2. ui.R: `htmlOutput("reportCard")`

## Data handling

In the current implementation, most of the student data is kept stored on the Shiny server and only sent to the user when the user requests different data. For instance, when the user hovers over a particular student on the interactive graph, the JavaScript code sends a message to Shiny requesting data for that student. The Shiny server then determines the appropriate HTML code to generate for that student's report card and sends that HTML code back to the user. 

Other code design is certainly possible. For instance, Shiny could send data to the user for all variables all at once, and then use JavaScript on the client side to directly modify HTML elements. Such an alternate design would not require further communication from Shiny after sending the initial data. This design may be useful if the developer wants to transition away from Shiny. However, other code would be necessary for interfacing with databases and analyzing/formatting data.

