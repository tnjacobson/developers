#Download PDFS

#Setting Paths
source(file.path(Sys.getenv("HOME"),"Documents/Github/developers","prelim.R"))
source(file.path(Sys.getenv("HOME"),"Documents/Github/developers","macros/functions.R"))

library(data.table)
library(tidyverse)
library(stringr)
library(sf)
library(tmap)    # for static and interactive maps
library(osmdata)

library(RSelenium)

# Start a Selenium server and open a browser session
rD <- rsDriver(browser = "chrome", port = 4444L, chromever = "latest")
remDr <- rD[["client"]]

# Navigate to the target webpage
remDr$navigate("https://chicityclerkelms.chicago.gov")


#Search within Box and Press Submit 

#Track data on committee dates 

#Download All Attachments