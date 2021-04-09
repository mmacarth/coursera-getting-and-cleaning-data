# coursera-getting-and-cleaning-data

## Overview

This repository contains the scripts required for preparing a clean data set for accelerometer
measurements.

One of the most exciting areas in all of data science right now is wearable computing - see for example this article . Companies like Fitbit, Nike, and Jawbone Up are racing to develop the most advanced algorithms to attract new users. The data linked to from the course website represent data collected from the accelerometers from the Samsung Galaxy S smartphone. A full description is available at the site where the data was obtained:

http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones

The data used in the project are downloaded from:

https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip

## Processing

The code to do the analysis is in a script called `run_analysis.R` invoked from a function
called `runAnalysis()`.

The `runAnalysis()` function does the following processing:

1. Downloads the zip file, https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip to a `data/row` subfolder. The `data/row` subfolder is created first if it doesn't exists.

2. Extracts the files needed for processing from the zip file into the `data/raw/UCI HAR Dataset` folder preserving the folder structure in the zip file. This structure consists of two sub folders, `train` and `test`, each with the following files:

   - subject_test.txt
   - X_test.txt
   - y_test.txt

3. The next step is step is to load the meta data containing activity labels and feature labels. These are loaded from `activity_labels.txt` and `features.txt` respectively. Two data frames are created:

   - `activityLabels` with two columns: `activityIndex` and activityLabel`. These are stored exactly as read from the activity_labels.txt file
   - `features` with three columns: `featureIndex`, `featureName` and `featureLabel`. featureIndex and featureName are read direction from features.txt, featureLabel is featureName with parentheses removed and other characters converted to '.' as they will be used later as column names

4. The next step extracts only the mean() and std() values into a new data.frame. This is done in the following steps:

   - Read all measurements from the train and test folders, the same processing is done for both:
     - read the subject\*.txt file into a data set, subjects
     - read the y\_\*.txt file into a data set, activities
     - read the X\_\*.txt file into a data set, measurements
     - add the data from the subjects and activities data sets as columns to the measurements data set
   - Merge the train and test measurements data sets together using `rbind`.
   - use the dplyr function select to extract only the mean() and std() columns; the column names for these are determined using a grep expression to find `mean()` and `std()`
   - using the activity index in the mean and std data set and the corresponding index in the activityLabels data sets add the activityLabel as a new column to the means and std data set. This data set is stored in a variable, `meanStDev`

5. Using the `meanStDev` dataset the average over activity and subject is determined by using the dplyr functions:

   - select: to get only the mean() values
   - group_by: to perform summarization on the groups defined by activity and subject:
   - summarise_all: to apply the mean() function to calculate averages over the defined groups
   - this data set is stored in a variable `averages`

6. The final step is to save the `averages` data set to a CSV file, the file is stored in the `data/processed` subfolder in a file named averages.csv.
