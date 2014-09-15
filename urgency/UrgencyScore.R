##############################################################
#############  Author : Himabindu Lakkaraju  #################
#############  Email : lvhimabindu@gmail.com #################
##############################################################

# UTILITY 
# This is the R-script that can be used to predict when a student is likely to go off-track. 
# Off-track, in our context, signifies that a student has either been retained or dropped-out 
# This piece of code picks up those candidates who are identified as at-risk by our prediction module and further 
# predicts the time point after which a student is likely to be retained or would drop-out (for the first time). 
# Note :- This code does "oversampling" of minority class instances in the training dataset. This code expects that missing values are
# accounted for already in the data either by imputation or by other means. 

# INPUTS

# This code takes 4 different inputs  

# Input 1 :- (offtrackfile) Path of the file containing id and first_time_off_track variable for each student. first_time_off_track indicates the grade when a student goes off-track relative to the first year. 
# For example, if we have data from grades 6 to 12. first_time_off_track should be coded with the values 1 (for grade 7), 2 (for grade 8) etc. 
# Remove the datapoints of students who drop out in grade 6 because predictions there do not say much. If a student never goes offtrack, assign the value which is equal to  offtrack values assigned as above + 1

# Input 2 :- (riskstudentids) Path of the file containing ids of the students who are at risk of not graduating on time (as given by our risk score prediction algorithm). Column 1 of this file has ids of students who are at risk in grade 7. Column 2 corresponds to students at risk at grade 8 and so on. 

# Input 3 :- (datafilespath) Path of the folder where there are separate data files for each grade. The files in this folder should be named as 7.csv, 8.csv etc. indicating the corresponding grade. Further, 8.csv would contain all the data from grade 6 to grade 8

# Input 4 :- (outputfilespath) Path of the folder where output should be dumped. Files named as 8.csv, 9.csv will be dumped. The number in the filename indicates the grade. 

# OUTPUTS

# This code outputs multiple prediction files each of which corresponds to a particular grade. Each line in each of these files has a pid, prediction, and true value. 


library(foreign)
library(ggplot2)
library(MASS)
library(Hmisc)
library(reshape2)
library(ordinal)
library(kimisc)
library(randomForest)

offtrackfile = temp1.csv
riskstudentids = temp2.csv
datafilespath = temp3.csv
outputfilespath = temp4.csv

oversample <- function(dat, fieldname) {
  
  print('-------------------------------------------')
  print('Function to oversample based on a particular column')
  
  minval <- min(dat[,fieldname])
  maxval <- max(dat[,fieldname])
  
  num_of_eles <- NULL
  
  maxnumrows <- 0
  
  for (i in minval:maxval)
  {
    val_to_put <- length(which(dat[,fieldname]==i))
    num_of_eles <- c(num_of_eles,val_to_put)
    if(val_to_put > maxnumrows)
    {
      maxnumrows <- val_to_put
    }
    
  }
  
  for (i in minval:maxval)
  {
    val_to_put <- num_of_eles[i]
    sizeval <- (maxnumrows - val_to_put)
    if(sizeval > 0 && val_to_put != 0)
    {
      dat <- rbind(dat,sample.rows(subset(dat, dat[,fieldname]==i), sizeval, replace=TRUE))
    }
  }
  
  return (dat)
}

addcolumnforfold <- function(dat, k=10, fieldname)
{
  print('-------------------------------------------')
  print('Function to add a column indicating the fold in which the data point is put')
  # make k folds of the data which preserve the distribution from the actual data
  
  minval <- min(dat[,fieldname])
  maxval <- max(dat[,fieldname])
  
  num_of_eles <- NULL
  
  
  for (i in minval:maxval)
  {
    val_to_put <- length(which(dat[,fieldname]==i))
    num_of_eles <- c(num_of_eles,val_to_put)
  }
  
  foldnum <- NULL
  count <- NULL
  for (i in 1:length(num_of_eles))
  {
    num_of_eles[i] <- ceiling((1.0/k) * num_of_eles[i])
    foldnum <- c(foldnum, 1)
    count <- c(count, 0)
  }
  
  # shuffle rows randomly 
  dat <- dat[sample(nrow(dat)),]
  
  dat["fold_numbers"] <- NA
  
  for (j in 1:dim(dat)[1])
  {
     # add current fold number as per foldnum vector 
     label <- dat[j,fieldname]
     index <- label
     dat[j,"fold_numbers"] <- foldnum[index]
     
     count[index] = count[index] + 1
     if(count[index] > num_of_eles[index])
     {
       foldnum[index] = foldnum[index] + 1
       count[index] = 0
     }
  }
  return(dat)
}



# ACC is the vector comprising of all the accuracies -- data till grade 8, data till grade 9, data till grade 10, data till grade 11
# MAE is the vector comprising of the Mean Absolute Errors -- data till grade 8, data till grade 9, data till grade 10, data till grade 11

ACC <- NULL
MAE <- NULL

for (i in 1:4)
{
  ACC <- cbind(ACC,0)
  MAE <- cbind(MAE,0.0)
  
}



# read the file which has time_to_off_track variable
dat2 <- read.csv(offtrackfile, header = TRUE, sep = ",")
head(dat2)

# read the file which has the indexes to work with at each grade
idsintop10 <- read.csv(riskstudentids, header = TRUE, sep = ",")
head(idsintop10)

# this is used to offset ranks when we move from one grade to another 
tosub = -1

# we are looking for data till the end of a particular grade to make the prediction of time to drop out 
for (grade in 8:11)
{
  
  print(paste('Processing data for grade',grade))
  tosub = tosub + 1
  
  # read the imputed file 
  dat1 <- read.csv(paste(datafilespath,"/",grade,".csv",sep=""), header = TRUE, sep = ",")
  head(dat1)
  dat1$nograd <- NULL
  
  # grade 7 is column 1 , which means we have to subtract 4 from grade variable
  gradeids <- idsintop10[,grade-4]
  head(gradeids)
  
  # merging all the files now 
  newdat <- NULL
  for (id in gradeids)
  {
    if ( ! is.na(id) )
    {
      idintable1 = match(id,dat1$pid)  # impute files index
      idintable2 = match(id,dat2$pid)  # offtrack info file index
      
      
      first_time_off_track_local = dat2[idintable2, "first_time_off_track"]
      
      if(is.na(first_time_off_track_local)) 
      {
        print("time_to_off_track not available")
        print(id)
        return
      }
      
      
      # offset times to start with 1
      first_time_off_track_local = first_time_off_track_local - tosub
      newdat <- rbind(newdat,cbind(dat1[idintable1, ], first_time_off_track_local))
      
    }
  } 
  
  # renaming the column
  l <- length(colnames(newdat))
  colnames(newdat)[l] <- "first_time_off_track"
  head(newdat)
  sum(is.na(newdat))
  
  
  
  # create the levels for the factor command
  levelvals <- NULL
  
  mini <- min(newdat$first_time_off_track)
  maxi <- max(newdat$first_time_off_trac)
  
  for (i in (mini:maxi))
  {
    levelvals <- cbind(levelvals,i)
  }
  
  if(sum(is.na(newdat)) > 0)
  {
    print("MISSING VALUES - TAKE CARE OF THOSE")
    return
  }
  dat <- NULL
  dat <- addcolumnforfold(newdat, 10, "first_time_off_track")
  count <- 0
  tuplenum <- 0
  difference <- 0
  
  predictionfile <- data.frame(pid = integer(0), prediction = integer(0), truth = integer(0))
  
  # now iterate over a loop and create train and test sets for doing the classification
  for (i in min(dat$fold_numbers):max(dat$fold_numbers))
  {
    train <- which(dat[,"fold_numbers"]!=i)
    test <- which(dat[,"fold_numbers"]==i)
    
    traindata <- dat[train,]
    testdata <- dat[test,]
    
    traindata$fold_numbers <- NULL
    testdata$fold_numbers <- NULL 
    
    traindata$pid <- NULL
    testpids <- testdata$pid 
    testdata$pid <- NULL
    
    traindata <- oversample(traindata, "first_time_off_track")
    
    m <- NULL
    
    traindata$first_time_off_track <- factor(traindata$first_time_off_track, levels = levelvals, ordered=TRUE)
   
    m <- randomForest(first_time_off_track ~ ., data = traindata, importance=TRUE, proximity=TRUE)
    
    predictedclass <- NULL
    
    predictedclass <- predict(m, newdata = testdata, type = "class")
    
    for(j in 1:dim(testdata)[1])
    {
      groundtruth <- as.numeric(testdata[j,"first_time_off_track"])
      prediction <- as.numeric(predictedclass[j])
      if(groundtruth == prediction)
      {
        count = count + 1
      }
      else
      {
        difference = difference + (abs(groundtruth-prediction))
      }
      
      tuplenum = tuplenum + 1
      
      predictionfile[tuplenum,"pid"] <- testpids[j]
      predictionfile[tuplenum,"prediction"] <- prediction
      predictionfile[tuplenum,"truth"] <- groundtruth
    }
    
  }
  
  ACC[grade-7] = count/(dim(dat)[1]+0.0)
  MAE[grade-7] = difference/(dim(dat)[1]+0.0)
  
  write.csv(predictionfile, file = paste(outputfilespath,"/",grade,".csv"))
}
