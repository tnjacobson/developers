#Create Distance to Border Tract File

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
library(foreign)

sf_use_s2(FALSE)


#-------------------------------------------------------------------------------
#Load in City Council 
#------------------------------------------------------------------------------
#Load in City Council Districts
nycc=  st_read(file.path(d_data,"raw/shapefiles/nycc_19d", "nycc.shp"))
nycc = nycc %>% 
  mutate(geo2 = geometry)


tracts=  st_read(file.path(d_data,"raw/shapefiles/tracts_2010_nyc", "tracts_2010_nyc.shp"))
tracts =st_transform(tracts, crs = st_crs(nycc))
tracts_centroids <- st_centroid(tracts)

tracts_centroids_join = st_join(tracts_centroids, nycc)

# Set 'geo2' as the default geometry column
tracts_centroids_join2 <- st_set_geometry(tracts_centroids_join, "geo2")

# Now remove the 'geometry' column by setting it to NULL
tracts_centroids_join2$geometry <- NULL

tracts_centroids_join2 = as.data.frame(tracts_centroids_join) %>%
  select(-geometry)

  tracts_centroids_join2=  st_as_sf(tracts_centroids_join2, geom_col = "geo2")

tracts_centroids_join$distances <- st_distance(tracts_centroids_join, st_boundary(tracts_centroids_join2), by_element = TRUE)


tracts_centroids_clean = tracts_centroids_join%>%
  select(boro_name, boro_code, ct2010, distance = distances) %>%
  as.data.frame()%>%
  select(-geometry)

write.csv(tracts_centroids_clean, file.path(d_data,"derived/tract_centroid_distances.csv"))


