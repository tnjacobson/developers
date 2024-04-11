##Create Building Panel

#Setting Paths
source(file.path(Sys.getenv("HOME"),"Documents/Github/developers","prelim.R"))
source(file.path(Sys.getenv("HOME"),"Documents/Github/developers","macros/functions.R"))

library(data.table)
library(tidyverse)
library(stringr)
library(sf)
library(tmap)    # for static and interactive maps
library(osmdata)
#-------------------------------------------------------------------------------
#Working with New Zoning Map
#-------------------------------------------------------------------------------

#Load in Map 
map <- st_read(file.path(d_data,"raw/zoning_nov23", "Zoning_asof_14NOV2023.shp"))
map =st_transform(map, crs = 4326)
map = st_make_valid(map)

check_coverage(map)

map = map %>%
  mutate(gap = ORDINANCE1 - CREATE_TIM)
# Group by 'UPDATE_TIM' and count the occurrences
collapse <- map %>%
  as.data.frame()%>%
  group_by(CREATE_TIM) %>%
  summarise(Count = n())

#-------------------------------------------------------------------------------
#Working with Developments
#-------------------------------------------------------------------------------
#Loading Qualities
commercial <- fread(file.path(d_data,"raw/assessor_cc", "commercial.csv"))
check_coverage(commercial)

