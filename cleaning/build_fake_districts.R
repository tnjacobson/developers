#Drawing Border

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


library(nngeo)
library(lwgeom)
library(dismo)
sf_use_s2(FALSE)


#-------------------------------------------------------------------------------
#Build Functions
#-------------------------------------------------------------------------------

# Define function that creates random borders
split_poly <- function(sf_poly, n_areas){
  
  # create random points
  points_rnd <- st_sample(sf_poly, size = 10000)
  #k-means clustering
  points <- do.call(rbind, st_geometry(points_rnd)) %>%
    as_tibble() %>% setNames(c("lon","lat"))
  k_means <- kmeans(points, centers = n_areas)
  # create voronoi polygons
  voronoi_polys <- dismo::voronoi(k_means$centers, ext = sf_poly)
  crs(voronoi_polys) <- crs(sf_poly)
  # clip to sf_poly
  voronoi_sf <- st_as_sf(voronoi_polys)
  voronoi_sf =st_transform(voronoi_sf, crs = 7801)
  
  equal_areas <- st_intersection(voronoi_sf, sf_poly)
  equal_areas$area <- st_area(equal_areas)
  return(equal_areas)
}


#Function to Compute HHI
compute_hhi <- function(housing, borders){
  #merge housing with borders
  
  housing_join = st_join(housing, borders)
  housing_join = housing_join%>%filter(!is.na(id))
  housing_join = as.data.frame(housing_join)
  
  housing_firm =  housing_join %>%
    group_by(id, firm)%>%
    summarise(proposeddwellingunits = sum(proposeddwellingunits, na.rm = TRUE))
  
  #District Counts
  district_counts <- housing_firm %>%
    group_by(id) %>%
    summarise(total_units = sum(proposeddwellingunits, na.rm = TRUE))
  
  #Add in District Counts
  housing_firm<- housing_firm %>%
    left_join(district_counts, by = "id")
  
  hhi_firms = housing_firm %>%
    mutate(district_share = ((proposeddwellingunits/total_units)*100)^2)%>%
    group_by(id) %>%
    summarise(hhi_firms = sum(district_share), total_units = sum(proposeddwellingunits))
  
  #Computing Independent
  #District Counts
  district_counts <- housing_join %>%
    group_by(id) %>%
    summarise(total_units = sum(proposeddwellingunits, na.rm = TRUE))
  #Add in District Counts
  housing_join<- housing_join %>%
    left_join(district_counts, by = "id")
  
  hhi_ind = housing_join %>%
    mutate(district_share = ((proposeddwellingunits/total_units)*100)^2)%>%
    group_by(id) %>%
    summarise(hhi_ind = sum(district_share), total_units = sum(proposeddwellingunits))
  
  merge = left_join(hhi_firms, hhi_ind, by = "id")
  
  
  weighted_hhi <- merge %>%
    mutate(relative = hhi_firms/hhi_ind) %>%
    summarise(weighted_avg = sum(relative * total_units.y) / sum(total_units.y)) %>%
    pull(weighted_avg)
  

  return(weighted_hhi)
}  

#-------------------------------------------------------------------------------
#Load Data
#-------------------------------------------------------------------------------
#Load in True CCDs
nycc=  st_read(file.path(d_data,"raw/shapefiles/nycc_23d", "nycc.shp"))
st_crs(nycc)$units
nycc =st_transform(nycc, crs = 7801)
nycc = nycc %>%
  mutate(id = CounDist, council_district = CounDist)

#Load in Boros
boroughs=  st_read(file.path(d_data,"raw/shapefiles/Borough Boundaries", "boroughs.shp"))

#Load in Housing Data
housing =   read.csv(file.path(d_data,"derived/nyc", "dob_permits_firm_ids_units.csv"))
housing = housing %>% 
  filter(!is.na(latitude))
housing_sf <- st_as_sf(housing, coords = c("longitude", "latitude"), crs = 4326)
housing_sf =st_transform(housing_sf, crs = 7801)



#-------------------------------------------------------------------------------
#Testing
#-------------------------------------------------------------------------------

bk = boroughs %>% filter(boro_code == 3)
bk =st_transform(bk, crs = 7801)
m = boroughs %>% filter(boro_code == 1)
m =st_transform(m, crs = 7801)
q= boroughs %>% filter(boro_code == 4)
q =st_transform(q, crs = 7801)

housing_sf_bk = st_join(housing_sf, bk) %>%
  filter(proposeddwellingunits >= 20) %>%
  filter(boro_code == 3) 

housing_sf_m = st_join(housing_sf, m) %>%
  filter(proposeddwellingunits >= 20) %>%
  filter(boro_code == 1) 

housing_sf_q = st_join(housing_sf, q) %>%
  filter(proposeddwellingunits >= 10) %>%
  filter(boro_code == 4) 

borders_true_bk= st_join(nycc, bk)  %>%
  filter(boro_code == 3)
borders_true_m= st_join(nycc, m)  %>%
  filter(boro_code == 1)
borders_true_q= st_join(nycc, q)  %>%
  filter(boro_code == 4)


borders_1 = split_poly(q, 18)
compute_hhi(housing_sf_q, borders_1)

compute_hhi(housing_sf_q, borders_true_q)




hhi_bk = hhi %>% left_join(borders_true, by = "council_district") %>%filter(boro_code == 3)

hhi_bk %>%
  summarise(weighted_avg = sum(hhi_firms * total_units) / sum(total_units)) %>%
  pull(weighted_avg)