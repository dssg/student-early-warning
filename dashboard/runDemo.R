# This script is used to run the student dashboard demo.
# The code loads/installs relevant packages and runs the Shiny app

# We used Shiny version 0.10.0 to write and run the Shiny app,
# and the plyr package version 1.8.1 to pre-process data
# Earlier versions of these packages may cause errors. 

if (require("shiny") == FALSE)  install.packages("shiny")
if (require("plyr")  == FALSE)  install.packages("plyr")

setwd("~/student-early-warning/")
runApp("dashboard", launch.browser=TRUE)