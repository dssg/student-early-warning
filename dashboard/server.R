# server.R

# This is the R code that specifies how to load, process, 
# and send the data to the user

# High-level summary of the code
#    1. load a CSV file 
#        > read.csv("data/data.csv")
#    2. add variables to the data frame (e.g., risk colors)
#        > allData() <- reactive({ ... })
#    3. gather the data to be plotted 
#        > plotDataGrades <- reactive({ ... })
#        > plotDataAbsen <- reactive({ ... })
#    4. send the data to be plotted to JavaScript
#        > observe({ session$sendCustomMessage(type="newStudents", data })
#    5. send HTML for student report card to ui.R
#        > output$reportCard <- renderUI({  return(createReportCard(currentData)) })

source("helpers.R")

# This helpers.R file defines the following functions
#    1. define mappings of values to colors
#        > colorRisk <- function(x) { ... }
#        > zColor <- function(z) { ... }
#    2. conversions from R data frame to Highcharts JSON
#        > formatPoint <- function(row) { ... } 
#        > formatStudent <- function(studentDf) { ... }
#        > highchartsConvert <- function(plotData) { ... } 
#        > plotData <- function(data, specs) { ... }
#    3. create HTML for student report card
#        > createReportCard <- function(currentStudent) { ... }

#standard function call for the Shiny server code
shinyServer(function(input, output, clientData, session) {

  ##############################
  #####      GET DATA      #####
  ##############################
  
  #Load data stored as a CSV on the Shiny server.
  #This code could be changed to load from a DB (e.g., using MySQL queries)
  rawData <- reactive ({
    return(read.csv("data/data.csv"))
  })
  
  ######################################
  #####      PRE-PROCESS DATA      #####
  ######################################
  
  #append with risk category, color, and formatted name for tooltip
  allData <- reactive ({
    data           <- rawData()
    data$pid       <- as.numeric(data$pid) #make sure that pid is stored as a numeric variable!!!
    data           <- data[order(data$pid),]  #order by pid
    data$riskColor <- lapply(data$risk9/100,colorRisk) #add the risk colors

    #add the z-scores for critical variables
    data$absrate_z  <- (data$absrate4-mean(data$absrate4,na.rm=T))/sd(data$absrate4,na.rm=T)
    data$nsusp_z    <- (data$nsusp4-mean(data$nsusp4,na.rm=T))/sd(data$nsusp4,na.rm=T)
    data$q4mpa_z    <- (data$q4mpa4-mean(data$q4mpa4,na.rm=T))/sd(data$q4mpa4,na.rm=T)
    data$mobility_z <- (data$mobility4-mean(data$mobility4,na.rm=T))/sd(data$mobility4,na.rm=T)
    
    return(data)
  })
  
  #############################################
  #####      GATHER THE DATA TO PLOT      #####
  #############################################
  
  #get risk scores data to send to Highcharts 
  plotDataRisk <- reactive({
    specs <- list(stem="risk", n_points=7, x_start=6, x_step=1)
    return(plotData(allData(),specs))
  })

  #get grades data to send to Highcharts 
  plotDataGrades <- reactive({
    specs <- list(stem="mpa", n_points=28, x_start=6.125, x_step=0.25)
    return(plotData(allData(),specs))
  })

  #get absences data to send to Highcharts 
  plotDataAbsen <- reactive({
    specs <- list(stem="absrate", n_points=7, x_start=6, x_step=1)
    return(plotData(allData(),specs))
  })

  #get mobility data to send to Highcharts 
  plotDataMobility <- reactive({
    specs <- list(stem="mobility", n_points=7, x_start=6, x_step=1)
    return(plotData(allData(),specs))
  })

  #get suspensions data to send to Highcharts 
  plotDataSusp <- reactive({
    specs <- list(stem="nsusp", n_points=7, x_start=6, x_step=1)
    return(plotData(allData(),specs))
  })

  #############################################
  #####      SEND DATA TO JAVASCRIPT      #####
  #############################################

  #store a named list of axis options
  axisOptions <- list(
    risk     = list(yTitle = "Risk Score",            yMin=-1,     yMax=101,   xMin=5.9, xMax=12.1),
    grades   = list(yTitle = "Grade Point Average",   yMin=-0.03,  yMax=4.03,  xMin=5.9, xMax=12.9),
    absen    = list(yTitle = "Absence Rate",          yMin=-0.1,   yMax=45,    xMin=5.9, xMax=12.1),
    mobility = list(yTitle = "Mobility",              yMin=-0.03,  yMax=4,     xMin=5.9, xMax=12.1),
    nsusp    = list(yTitle = "Number of Suspensions", yMin=-0.015, yMax=2,     xMin=5.9, xMax=12.1)
  )

  #send data to JavaScript so that Highcharts can plot it
  observe({
    defaultData <- c(axisOptions$grades, list(series=plotDataGrades()))
    session$sendCustomMessage(type="newStudents",defaultData)
  })
  
  
  #send grades data to JavaScript if the grades button is pushed
  observe({
    if (!is.null(input$riskButton) && input$riskButton>0) {
      newData <- c(axisOptions$risk, list(series=plotDataRisk()))
      session$sendCustomMessage(type="updateVariable", newData)
    } 
  })
  
  
  #send grades data to JavaScript if the grades button is pushed
  observe({
    if (!is.null(input$gpaButton) && input$gpaButton>0) {
      newData <- c(axisOptions$grades, list(series=plotDataGrades()))
      session$sendCustomMessage(type="updateVariable", newData)
    } 
  })

  #send absences data to JavaScript if the absences button is pushed
  observe({
    if (!is.null(input$absenButton) && input$absenButton>0) {
      newData <- c(axisOptions$absen, list(series=plotDataAbsen()))
      session$sendCustomMessage(type="updateVariable",newData)
    } 
  })

  #send mobility data to JavaScript if the mobility button is pushed
  observe({
    if (!is.null(input$mobButton) && input$mobButton>0) {
      newData <- c(axisOptions$mob, list(series=plotDataMobility()))
      session$sendCustomMessage(type="updateVariable",newData)
    } 
  })

  #send suspensions data to JavaScript if the suspensions button is pushed
  observe({
    if (!is.null(input$suspButton) && input$suspButton>0) {
      newData <- c(axisOptions$nsusp, list(series=plotDataSusp()))
      session$sendCustomMessage(type="updateVariable",newData)
    } 
  })

  
  ################################################
  #####      OUTPUT STUDENT REPORT CARD      #####
  ################################################

  #this function will return HTML code for the student report card
  output$reportCard <- renderUI({

    #if no specific student has been selected yet, then don't return 
    #a report card. The variable input$selectID will be updated by  
    #the JavaScript code using ...
    #    > Shiny.onInputChange("selectID", this.data[0].id);
    if (is.null(input$selectID)) return(NULL)

    #get the student level data to create the student report card
    currentData <- subset(allData(),pid==input$selectID)

    #send the report card to ui.R
    return(createReportCard(currentData,currentGrade))
  })
  

})