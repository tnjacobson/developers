#Extracting Data from Zoning Applications


#Setting Paths
source(file.path(Sys.getenv("HOME"),"Documents/Github/developers","prelim.R"))
library(data.table)
library(stringr)
library(httr)
library(jsonlite)
library(tidygeocoder)

#-------------------------------------------------------------------------------
#Extracting Application Text
#-------------------------------------------------------------------------------


final_data <- data.frame()


years <- 2010:2023  # for instance, from 2001 to 2020
year = 2019
#for (year in years) {
  
  #Load in Data
  data <- fread(file.path(d_data,"raw/councilmatic", paste0("zoning",year,".csv")))
  
  #Pull out text with application in it
  data$application_text <- str_extract(data$extras, "(?<=APPLICATION FOR AN AMENDMENT TO THE CHICAGO ZONING ORDINANCE)(.*?)(?=NOTARY PUBLIC)")
  
  #Check how many have application
  data[, clean_application := ifelse(!is.na(application_text), 1, 0)]
  print(mean(data$clean_application))

#}