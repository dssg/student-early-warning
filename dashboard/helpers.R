###############################################
#####      DEFINE COLORING FUNCTIONS      #####
###############################################

#inputs a risk score from 0 to 1, outputs a desired color
colorRisk <- function(x) {
  shades <- colorRampPalette(c("#888888", "red"))(101) #create 101 shades of grey to red
  maxVal <- .8 #all risk scores above this score are colored "red"
  index <- min(round(x*100)*(1/maxVal)+1,100)+1 #find which color index to choose
  return(shades[index])
}

#inputs a z score, outputs a desired color 
zColor <- function(z) {
  #create 101 shades of blue to white to red
  shades <- colorRampPalette(c("blue", "white", "red"))(101) 
  
  #all absolute values greater than maxZ get colored the same
  maxZ <- 2 
  newZ <- min(abs(z),maxZ)*sign(z)

  #find which color index to choose
  index <- round(newZ*(50/maxZ))+51 
  return(shades[index])
}

######################################################
#####      DEFINE JSON CONVERSION FUNCTIONS      #####
######################################################

#create a JSON that Highcharts (a JavaScript library) can understand
#     plotData and highchartsConvert are the main functions
#     formatPoint, formatStudent, and newOrder are helper functions for them

#formatPoint takes in a row representing one data point (e.g., student #45's
#grades in 10th grade) and outputs a named list that Highcharts
#will understand
#In JavaScript, a data point would look like {x: 10, y: 2.5, id: 45}
formatPoint <- function(row) {
  return( list( x=row$x, y=row$y, id=row$id))
}


#formatStudents takes in a data frame representing all the data to plot for a 
#particular student (e.g., student #45) and outputs a named list that Highcharts
#will understand
#In JavaScript, data for a student would look like 
#          {name: "David Miller",
#           color: "#FF0000",
#           data: [
#                   {x: 6, y: 2.5, id: 45},
#                   {x: 7, y: 2.8, id: 45},
#                   {x: 8, y: 3.0, id: 45},
#                   {x: 9, y: 2.8, id: 45},
#                   {x: 10, y: 2.5, id: 45},
#                   {x: 11, y: 2.0, id: 45},
#                   {x: 12, y: 1.9, id: 45}
#                 ]
#          }
#
formatStudent <- function(studentDf) {
  studentTemplate <- list(name="",color="",data={})
  studentTemplate$name <- as.character(studentDf$name[[1]])
  studentTemplate$color <- as.character(studentDf$color[[1]])

  #dlply will split splitDf into its rows, apply the function formatPoint to
  #each row, and then combine the results as a named list 
  dataPoints <- dlply(studentDf,.(1:nrow(studentDf)),formatPoint)
  names(dataPoints) <- NULL #don't actually want a named list in the end
  studentTemplate$data <- dataPoints

  return(studentTemplate)
}



#using the functions formatPoint and formatStudent, 
#create a JSON that can be inputed into highcharts 
highchartsConvert <- function(plotData) {

  #convert data frame to json format using the two format functions defined earlier.
  #dlply will split plotData by id, apply the function formatStudent to 
  #each subset, and then combine the results as a named list
  json <- dlply (plotData, .(id), formatStudent)

  #almost there, but the students are currently sorted by id
  #we want to sort by risk score instead
  json <- json[ newOrder(plotData) ] 
  names(json) <- NULL   #we want an unnamed list in the end

  #NOTE: this way of ordering assumes reactiveSubset() was already 
  #sorted by id (just like json before re-ordering). Earlier code
  #ensured that this was the case

  return(json)
}


#takes in the same data as highchartsConvert, figures out how
#the intermediate json in highchartsConvert will be ordered by id,
#and returns a new ordering that will order by risk category
newOrder <- function(plotData) {
  getRisk <- function(row) return( row$risk[1] )
  risks <- unlist(dlply(plotData, .(id), getRisk))
  return (order(risks, decreasing=TRUE))
}


#we want a data frame in long format with all the information that
#we need for plotting (x values, y values, IDs, colors, and risk scores)
plotData <- function(data, specs) {
  stem <- specs$stem 
  n_points <- specs$n_points 
  x_step <- specs$x_step
  x_start <- specs$x_start

  #get the data in wide format for the relevant variables 
  wideData <- data[grep(specs$stem,colnames(data))][1:n_points] 
  colnames(wideData) <- paste0("y",1:n_points) #change variable names
  wideData$id <- data$pid #store the IDs of students (e.g., student 47)    
  wideData$name <- data$name
  wideData$color <- data$riskColor
  wideData$risk <- data$risk9/100 #risk scores

  #convert wide to long form
  longData <- reshape(wideData, varying=paste0("y",1:n_points), 
                       direction="long", idvar="id",sep="",timevar="x")
  longData <- longData[order(longData$id),] #reorder so that students are in chunks of rows

  #make the "x" variable represent current grade level 
  #For instance, x = 6 corresponds to grade 6 
  longData$x <- x_start+x_step*(longData$x-1)

  #convert long data to a JSON that Highcharts will be able to parse
  plotData <- highchartsConvert(longData)
  return(plotData)
}

################################################
#####      CREATE STUDENT REPORT CARD      #####
################################################


#this function will return HTML code for the student report card
createReportCard <- function(currentStudent, grade=12) {
  
  #get text for values for critical variables
  abs <- paste0(sprintf("%.1f",currentStudent$absrate4),"%")
  susp <- sprintf("%.2f",currentStudent$nsusp4)
  mpa <- sprintf("%.2f",mean(currentStudent$q4mpa4))
  mob <- sprintf("%.2f",(currentStudent$mobility4))
  risk <- floor(currentStudent$risk9)
    
  #get colors for critical variables
  absCol <- zColor(currentStudent$absrate_z)
  suspCol <- zColor(currentStudent$nsusp_z)
  mpaCol <- zColor(-currentStudent$q4mpa_z)
  mobCol <- zColor(currentStudent$mobility_z)
  riskCol <- colorRisk(currentStudent$risk9/100)

  url <- currentStudent$url
  imageurl <- currentStudent$imageurl

  #specify the header that goes above the report card
  reportHeader <- paste0("Report Card for ",currentStudent$name)

  #return the HTML code for the student report card
  #it's necessary to wrap the code using HTML( ... )
  #or otherwise Shiny will just interpret the returned value 
  #as just a string 
  return(HTML(paste0(
    '<style>
      .databutton {
        float:left;
        width:100px;
        height:75px;
        margin-top: 0px;
        margin-left: 0px;
        margin-right: 50px;
      }

      .datacontainer {
        width:100px;
        height:75px;
        border: 2px inset gray;
        border-radius: 10px;
        margin-top: 5px;
        text-align:center;
        line-height:25px;
        font-size:25px;
      }
    </style>


    <div style="height:300px; width:900px;"><center>
      <h3><div id="reportHeader" onclick=update()>',reportHeader,'</div></h3>

      <div class="databutton">
        Risk Score
        <button id="riskButton" class="action-button datacontainer" style="background-color:',riskCol,';">',risk,'</button>
      </div>

      <div class="databutton">
        GPA
        <button id="gpaButton" class="action-button datacontainer" style="background-color:',mpaCol,';">',mpa,'</button>
      </div>

      <div class="databutton">
        Absence Rate
        <button id="absenButton" class="action-button datacontainer" style="background-color:',absCol,';">',abs,'</button>
      </div>

      <div class="databutton">
        Suspensions
        <button id="suspButton" class="action-button datacontainer" style="background-color:',suspCol,';">',susp,'</button>
      </div>
   
      <div class="databutton">
        Mobility
        <button id="mobButton" class="action-button datacontainer" style="background-color:',mobCol,';">',mob,'</button>
      </div>
      
      <div style="margin-right:0px; align:left; margin-left:0px;">
        <a target="_blank" href="',url,'">
        <img src="',imageurl,'" height="100" width="100"/>
        </a>
      </div>

    </center></div>'
  )))

}
