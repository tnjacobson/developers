#Geocode and Extract Useful Information From Agendas

#Setting Paths
source(file.path(Sys.getenv("HOME"),"Documents/Github/developers","prelim.R"))
source(file.path(Sys.getenv("HOME"),"Documents/Github/developers","macros/functions.R"))

library(data.table)
library(tidyverse)
library(stringr)
library(sf)
library(tmap)    # for static and interactive maps
library(osmdata)


#Function for speeding up
st_intersection_faster <- function(x,y,...){
  #faster replacement for st_intersection(x, y,...)
  
  y_subset <-
    st_intersects(x, y) %>%
    unlist() %>%
    unique() %>%
    sort() %>%
    {y[.,]}
  
  st_intersection(x, y_subset,...)
}

#-------------------------------------------------------------------------------
#Load in Data
#-------------------------------------------------------------------------------
map <- st_read(file.path(d_data,"raw/zoning_nov23", "Zoning_asof_14NOV2023.shp"))
map =st_transform(map, crs = 4326)
map = st_make_valid(map)


#Check What's Missing 
check_coverage(map)

map_1189 = map %>% filter(PD_NUM == 1190)