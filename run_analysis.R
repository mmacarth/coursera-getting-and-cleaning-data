library(dplyr)

rawDataFolder <- "data/raw"
processedDataFolder <- "data/processed"
zipFileName <- "getdata_projectfiles_UCI HAR Dataset.zip"
zipFullFileName <- file.path(rawDataFolder, zipFileName)
zipFolder <- "UCI HAR Dataset"
subjectColName.Index <- "subjectIndex"
activityColName.Index <- "activityIndex"
activityColName.Label <- "activityLabel"
featureColName.Index <- "featureIndex"
featureColName.Name <- "featureName"

# Download the data accelerometer data to a data subfolder. First check if the data# folder exists, if it doesn't create it.
downloadData <- function() {
        if (!dir.exists(rawDataFolder)) {
                dir.create(rawDataFolder, recursive = TRUE)
        }
        download.file("https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip", 
                      destfile = zipFullFileName, method = "curl")
}

# The downloaded file is zipped so extract files needed for processing 
unzipData <- function() {
        fileList = c(file.path(zipFolder, "activity_labels.txt"), 
                     file.path(zipFolder, "features.txt"), 
                     file.path(zipFolder, "test", "subject_test.txt"), 
                     file.path(zipFolder, "test", "X_test.txt"),
                     file.path(zipFolder, "test", "y_test.txt"),
                     file.path(zipFolder, "train", "subject_train.txt"), 
                     file.path(zipFolder, "train", "X_train.txt"),
                     file.path(zipFolder, "train", "y_train.txt"))
        unzip(zipFullFileName, exdir = rawDataFolder, files = fileList, overwrite = TRUE)
}

# Read the labels for the activities
getActivityLabels <- function() {
        fileName <- file.path(rawDataFolder, zipFolder, "activity_labels.txt")
        activityLabels <- read.table(fileName, sep = " ", col.names = c(all_of(activityColName.Index), all_of(activityColName.Label)))
        
        activityLabels
}

# Read the list of features to use in assigning column names
getFeatures <- function() {
        fileName <- file.path(rawDataFolder, zipFolder, "features.txt")
        features <- read.table(fileName, sep = " ", col.names = c(featureColName.Index, featureColName.Name))
        
        # clean up labels so they can be used as column headings
        features$featureLabel <- cleanName(features$featureName)
        
        features
}

# The feature names include parentheses, these do not translate to column
# names nicely so removed them. Also replace commas and dashes with dots.
cleanName <- function(featureNames) {
        
        names <- gsub("[\\(\\)]", "", featureNames)
        names <- gsub("[,-]", ".", names)
        
        names
}

getMeansAndStDevs <- function(features, activityLabels) {
        # Merge the training and the test sets to create one data set.
        mergedSets <- mergeTrainTest(features)
        
        # Extract only the measurements on the mean and standard deviation for each measurement. 
        meanStDev <- getMeanStDev(features, mergedSets)
        
        # Use descriptive activity names to name the activities in the data set
        meanStDev <- assignActivityNames(meanStDev, activityLabels)
}

# 
# get a table of measurements from the specified source
# Use the feature labels for the measurement column headings
getMeasurements <- function(featureLabels, source) {
        folder <- file.path(rawDataFolder, zipFolder, source)
        
        subjectFilename <- paste(folder, "/", "subject_", source, ".txt", sep = "")
        subjects <- read.table(subjectFilename, col.names = c(all_of(subjectColName.Index)))
        
        activitiesFileName <- paste(folder, "/", "y_", source, ".txt", sep = "")
        activities <- read.table(activitiesFileName, col.names = c(activityColName.Index))

        measurementsFileName <- paste(folder, "/", "x_", source, ".txt", sep = "")
        measurements <- read.table(measurementsFileName, col.names = featureLabels)

        measurements$subjectIndex <- subjects[,subjectColName.Index]
        measurements$activityIndex <- activities[,activityColName.Index]
        
        measurements
}

mergeTrainTest <- function(features) {
        testMeasures <- getMeasurements(features$featureLabel, "test")
        trainMeasures <- getMeasurements(features$featureLabel, "train")
        
        measures <- rbind(testMeasures, trainMeasures)
}

# Get all mean features by using a regular expression to find names containing
# mean()
getMeanFeatureNames <- function(features) {
        features[grepl("\\bmean\\(\\)", features$featureName), "featureLabel"]
}

# Get all std features by using a regular expression to find names containing
# std()
getStandardDevFeatureNames <- function(features) {
        features[grepl("\\bstd\\(\\)", features$featureName), "featureLabel"]
}

getMeanStDev <- function(features, measures) {
        # get features which are the mean and std, these are identified by
        # having mean() or std() in the feature name
        
        # get mean and std measures and activity and subject indices
        meanStdDevsMeasures <- select(measures, 
                                      getMeanFeatureNames(features), 
                                      getStandardDevFeatureNames(features), 
                                      all_of(activityColName.Index), 
                                      all_of(subjectColName.Index))
        
        meanStdDevsMeasures
}

assignActivityNames <- function(measures, activityLabels) {
        withLabels <- inner_join(measures, activityLabels)
        
        withLabels
}

# The main runAnalysis function which downloads and processes the
# data
runAnalysis <- function() {
        # Download and unzip the data
        downloadData()
        unzipData()
        
        # Load the common meta data
        activityLabels = getActivityLabels()
        features <- getFeatures()
        
        # Extract the mean and standard deviation values from the measurements
        meanStDev <- getMeansAndStDevs(features, activityLabels)

        # From the mean and standard deviation data set above, create a second dataset
        # with the average of each variable for each activity and subject
        averages <- meanStDev %>% 
                select(getMeanFeatureNames(features), 
                       subjectIndex, 
                       activityLabel) %>%
                group_by(subjectIndex, activityLabel) %>% 
                summarise_all(mean)
        
        if (!dir.exists(processedDataFolder)) {
                dir.create(processedDataFolder, recursive = TRUE)
        }
        
        # Save the data frame with the set of averages to a CSV file named averages
        write.table(averages, sep = ",", file = file.path(processedDataFolder, "averages.csv"))
}