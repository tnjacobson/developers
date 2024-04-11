#Construct NYC Housing Data

#Setting Paths
source(file.path(Sys.getenv("HOME"),"Documents/Github/developers","prelim.R"))
source(file.path(Sys.getenv("HOME"),"Documents/Github/developers","macros/functions.R"))

library(data.table)
library(tidyverse)
library(stringr)
library(sf)
library(tmap)    # for static and interactive maps
library(osmdata)
# Load the readxl package
library(readxl)


#-------------------------------------------------------------------------------
#Load in Data
#-------------------------------------------------------------------------------
#Loading in Housing Database 
housingdb = st_read(file.path(d_data,"raw/nyc_housing/nychdb_inactiveincluded_23q2_shp", 
                              "/HousingDB_post2010_inactive_included.shp"))
check = check_coverage(housingdb)

#Load in Zoning Database
zap <- read.csv(file.path(d_data,"raw/nyc_housing/nyc_zap/zapprojects_20240101csv", "zap_projects.csv"))
zap_short = zap %>%
  select(project_id, project_name, project_brief, project_status, 
         ulurp_non, primary_applicant, current_milestone, app_filed_date)%>%
  mutate(no_applicant =as.numeric( primary_applicant == "Unknown"))
mean(zap_short$no_applicant)

project_data =  read.csv(file.path(d_data,"raw/nyc_housing", "Housing_Database_Project_Level_Files_20240129.csv"))
permits =  read.csv(file.path(d_data,"raw/nyc_housing", "DOB_NOW__Build___Approved_Permits_20240129.csv"))

# Convert the Issued.Date variable to a POSIXct object
permits$Issued.Date <- as.POSIXct(permits$Issued.Date, format = "%m/%d/%Y %I:%M:%S %p")

# Extract the year component
permits$Year <- format(permits$Issued.Date, "%Y")


#Loading in BBLs
zapbbl <- read.csv(file.path(d_data,"raw/nyc_housing/nyc_zap/zapprojectbbls_20240101csv", "zap_projectbbls.csv"))
zapbbl = zapbbl %>%
  select(project_id, bbl)
is_unique <- length(unique(zapbbl$bbl)) == length(zapbbl$bbl)

#Loading in Doing Business 
bus <- read.csv(file.path(d_data,"raw/nyc_doing_business", "DBDB_Download.csv"))

#-------------------------------------------------------------------------------
#Looking Up Specific Buildings
#-------------------------------------------------------------------------------
permits_filter = permits %>%
    filter(Borough == "BROOKLYN") %>%
    filter(Block == 388)

zap = zap %>%
  select()

housingdb = housingdb %>%
  select(Job_Number, BBL, AddressNum, AddressSt, ClassANet, DateFiled, DatePermit, DateComplt)


