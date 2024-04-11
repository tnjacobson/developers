#Exploring RD

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


#Load in City Council Districts
nycc=  st_read(file.path(d_data,"raw/shapefiles/nycc_23d", "nycc.shp"))
st_crs(nycc)$units
nycc =st_transform(nycc, crs = 7801)
nycc = nycc %>%
  select(council_district = CounDist)
nycc_valid = st_make_valid(nycc)

# Add a new column 'num_polygons' to 'nycc' with the number of polygons for each row
nycc$num_polygons <- sapply(st_geometry(nycc), function(geom) {
  if (inherits(geom, "MULTIPOLYGON")) {
    sum(sapply(geom, length))
  } else if (inherits(geom, "POLYGON")) {
    1
  } else {
    0  # In case there are geometries that are not polygons
  }
})


nycc_valid$num_polygons <- sapply(st_geometry(nycc_valid), function(geom) {
  if (inherits(geom, "MULTIPOLYGON")) {
    sum(sapply(geom, length))
  } else if (inherits(geom, "POLYGON")) {
    1
  } else {
    0  # In case there are geometries that are not polygons
  }
})


#Creating Rings:
size = 50

# Initialize list to store results for each district
nycc_outerdiffs1 = list()
nycc_outerdiffs2 = list()
nycc_outerdiffs3 = list()

nycc_innerdiffs1 = list()


nycc_districts = list()
for (district in 1:51) {
  nycc_filter = filter(nycc,  council_district == district)
  nycc_districts[[district]] = nycc_filter
  
  #Computing First Border
  nycc_outer1 = st_buffer(nycc_filter, dist = size)
  nycc_outerdiff1 = st_difference(nycc_outer1,nycc_filter, dimension = "polygon")
  nycc_outerdiffs1[[district]] = nycc_outerdiff1
  
  #Computing Second Border
  nycc_outer2 = st_buffer(nycc_filter, dist = 2*size)
  nycc_outerdiff2 = st_difference(nycc_outer2,nycc_outer1, dimension = "polygon")
  nycc_outerdiffs2[[district]] = nycc_outerdiff2
  
  #Computing Third Border
  nycc_outer3 = st_buffer(nycc_filter, dist = 3*size)
  nycc_outerdiff3 = st_difference(nycc_outer3,nycc_outer2, dimension = "polygon")
  nycc_outerdiffs3[[district]] = nycc_outerdiff3
  
  #Inner Boundaries
  nycc_inner1 = st_buffer(nycc_filter, dist = -size)
  nycc_innerdiff1 = st_difference(nycc_filter, nycc_inner1, dimension = "polygon")
  nycc_innerdiffs1[[district]] = nycc_inner1
  
}

nycc_inner1 = st_buffer(nycc_filter, dist = -size)
nyccsimple = st_simplify(nycc_filter)
nycc_inner1 = st_buffer(nyccsimple, dist =  set_units(-0.05, degree))

#Map
ggplot()  +
  geom_sf(data = nycc_outerdiffs3[[1]], color = "black", fill = "lightgray") +
  geom_sf(data = nycc_outerdiffs2[[1]], color = "forestgreen", fill = "lightgreen") +
  geom_sf(data = nycc_outerdiffs1[[1]], color = "blue", fill = "lightblue") + 
  geom_sf(data = nycc_districts[[1]], color = "maroon", fill = "maroon") + 
  geom_sf(data = nycc_innerdiffs1[[1]], color = "orange", fill = "orange") + 
  theme_minimal()

#Map
ggplot()  +
  geom_sf(data = nycc_outerdiffs3[[51]], color = "black", fill = "lightgray") +
  geom_sf(data = nycc_outerdiffs2[[51]], color = "forestgreen", fill = "lightgreen") +
  geom_sf(data = nycc_outerdiffs1[[51]], color = "blue", fill = "lightblue") + 
  geom_sf(data = nycc_districts[[51]], color = "maroon", fill = "maroon") + 
  geom_sf(data = nycc_innerdiffs1[[51]], color = "orange", fill = "orange") + 
  theme_minimal()

ggplot()+ 
  geom_sf(data = nyccsimple, color = "orange", fill = "orange") + 
  theme_minimal()





#Loading in Stata Dataset for Housing
housing =   read.csv(file.path(d_data,"derived/nyc", "dob_permits_firm_ids_units.csv"))
housing = housing %>% 
  filter(!is.na(latitude))
housing_sf <- st_as_sf(housing, coords = c("longitude", "latitude"), crs = 4326)

#Merge in Qualities

#Restrict to Projects with at least 10 units
housing_l = housing %>%
  filter(proposeddwellingunits>=10)%>%
  group_by(firm) %>%
  arrange(firm, issuance_date) %>%
  mutate(first_council_district = first(council_district)) %>%
  ungroup()

housing_sf_l = housing_sf %>%
  filter(proposeddwellingunits>=10)%>%
  group_by(firm) %>%
  arrange(firm, issuance_date) %>%
  mutate(first_council_district = first(council_district)) %>%
  ungroup()


#List of Firms
firm_list =  unique(housing_l$firm)

#For a particular firm
firm = "2124213535"

#Find city council district (council_district) associated with earliest project (issuance_date)
council_district = housing_l%>%
  filter(firm = firm)

#For a single firm, find first project and associated city council district




