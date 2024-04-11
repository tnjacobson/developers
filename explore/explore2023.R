
#Explore Most Recent Map

#Setting Paths
source(file.path(Sys.getenv("HOME"),"Documents/Github/developers","prelim.R"))
source(file.path(Sys.getenv("HOME"),"Documents/Github/developers","macros/functions.R"))

library(data.table)
library(tidyverse)
library(stringr)
library(sf)
library(tmap)    # for static and interactive maps
library(osmdata)

zoning2023 <- st_read(file.path(d_data,"raw/second_city_zoning_2023_10_25", "second_city_zoning_2023_10_25.shp"))


#Convert DAtate

# Define the ESRI epoch date (in milliseconds since January 1, 1970)
esri_epoch <- as.Date("1970-01-01")

# Convert the ESRI date to a normal date
zoning2023=zoning2023 %>%
    mutate(date = as.Date(esri_epoch + create_tim / 1000, origin = "1970-01-01"))
check_coverage(zoning2023)


