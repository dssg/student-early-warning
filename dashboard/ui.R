
#ui.R 

#This is the R code that specifies how the output should be displayed
#to the user. Shiny will take this R code and convert to HTML. 

#The code also demonstrates how to use tags and HTML in Shiny to 
#customize the display

#See the article below about HMTL customization in Shiny
#http://shiny.rstudio.com/articles/html-tags.html

#load libraries
library(shiny)
library(plyr)

#shinyUI will convert the contained R code to appropriate HTML code
shinyUI(
                        
  #create a navigation bar layout
  navbarPage("Risk score visualizations",   

    #first navigation tab               
    tabPanel("Student dashboard",

      #load appropriate JavaScript libraries
      #Shiny will load these scripts from the "wwww" folder
      tags$script(src="libraries/jquery-1.9.1.min.js")
      ,tags$script(src="libraries/highcharts.js")
      ,tags$script(src="libraries/highcharts-more.js")
      ,tags$script(src="libraries/exporting.js")   


      #create the time series chart
      ,tags$div(id="highChart")   #create a division for the Highcharts chart
      ,tags$script(src="chart.js") #fill in the division using JavaScript

      #create the student report card
      ,htmlOutput("reportCard")
    )
  )
)
