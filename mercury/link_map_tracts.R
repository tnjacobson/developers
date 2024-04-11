#Load in Packages 
library(data.table)
library(tidyverse)
library(stringr)
library(sf)


#Set Working Directory 
setwd("/home/tjacobs0")
derived<-"./developers/derived"
raw <- "./developers/raw"

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
zoning2012 <- st_read(file.path(raw,"Zoning 2012", "Zoning_nov2012.shp"))
print("Loaded File")
zoning2012 = st_make_valid(zoning2012)
zoning2012 =st_transform(zoning2012, crs = 4326)

zoning2012_simple = st_simplify(zoning2012)%>%
                            select(zone_class_2012 = ZONE_CLASS)

zoningcurrent <- st_read(file.path(raw,"zoning_nov23", "Zoning_asof_14NOV2023.shp"))
zoningcurrent = st_make_valid(zoningcurrent)

zoningcurrent =st_transform(zoningcurrent, crs = 4326)
zoningcurrent_simple = st_simplify(zoningcurrent) %>%
                            select(object_id2023 = OBJECTID, zone_class_2023 = ZONE_CLASS, recent_ordinance_date = ORDINANCE1)

#-------------------------------------------------------------------------------
#Add Ward
#-------------------------------------------------------------------------------
wards <- st_read(file.path(raw,"wards_2015", "wards_2015.shp"))
wards = st_make_valid(wards)
wards =st_transform(wards, crs = 4326)


intersection_current_wards <- st_intersection_faster(wards, zoningcurrent_simple)
intersection_2012_wards <- st_intersection_faster(wards, zoning2012_simple)

saveRDS(intersection_current_wards,file.path(derived, "intersection_current_ward.RDS"))
saveRDS(intersection_2012_wards,file.path(derived, "intersection_2012_ward.RDS"))


#-------------------------------------------------------------------------------
#Add Census Tract
#-------------------------------------------------------------------------------

# Step 1: Load the 2010 Tract Shapefile for Cook County, IL
chicago_tracts <- st_read(file.path(raw,"tracts_2010", "tracts_2010.shp"))

# Step 2: Transform and make valid the cook_county_tracts data
chicago_tracts <- st_transform(chicago_tracts, crs = 4326)
chicago_tracts <- st_make_valid(chicago_tracts)
chicago_tracts <- st_simplify(chicago_tracts)




#Try Intersection
#intersection_current <- st_intersection_faster(chicago_tracts, zoningcurrent_simple)
intersection_2012 <- st_intersection_faster(chicago_tracts, zoning2012_simple)

#saveRDS(intersection_current,file.path(derived, "intersection_current.RDS"))
saveRDS(intersection_2012,file.path(derived, "intersection_2012.RDS"))



#-------------------------------------------------------------------------------
#Intersecting Maps
#-------------------------------------------------------------------------------
intersection_map = st_intersection_faster(zoning2012_simple, zoningcurrent_simple)
saveRDS(intersection_map,file.path(derived, "intersection_maps.RDS"))
