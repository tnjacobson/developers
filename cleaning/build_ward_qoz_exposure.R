#Build Opportunity Zone Ward Exposure

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


# Specify the file path to your Excel spreadsheet

# Read the Excel file and skip the first 4 rows
qozs <- read_excel(file.path(d_data,"raw/opp_zones", "designated-qozs.12.14.18.xlsx"), skip = 4)
qozs = qozs %>%
  select(geoid = `Census Tract Number`) %>%
  mutate(qoz = 1 )

#-------------------------------------------------------------------------------
#Chicago
#-------------------------------------------------------------------------------
#Load in Wards and Tracts
wards_2015 =  st_read(file.path(d_data,"raw/shapefiles/wards_2015", "wards_2015.shp"))
wards_2015 =st_transform(wards_2015, crs = 4326)
wards_2015 = wards_2015 %>%
  select(ward2015 = ward) 
wards_2015$ward_area <- st_area(wards_2015)


#Load in Tracts
tracts =st_read(file.path(d_data,"raw/shapefiles/tracts_2010", "tracts_2010.shp"))
tracts =st_transform(tracts, crs = 4326)
tracts = tracts %>%
  select(tract = geoid10)

#Merging Tracts Together:
tracts_qoz = left_join(tracts, qozs, by=c("tract"))
tracts_qoz = tracts_qoz %>%
  mutate(qoz = ifelse(is.na(qoz),0,1))


#Intersecting with Wards
intersect_ward_qozs = st_intersection(wards_2015, tracts_qoz )
intersect_ward_qozs$intersect_area <- st_area(intersect_ward_qozs)
intersect_ward_qozs = intersect_ward_qozs %>%
  mutate(frac_ward = as.numeric(intersect_area/ward_area)) %>%
  mutate(ward2015 = as.numeric(ward2015))

#Computing Exposure 
intersect_ward_qozs_collapse <- intersect_ward_qozs %>%
  group_by(ward2015) %>%
  summarize(frac_qoz = weighted.mean(qoz, w = frac_ward))

#Exporting
ward_exposure = intersect_ward_qozs_collapse %>%
  select(ward2015, frac_qoz)%>%
  as.data.frame() %>%
  select(-geometry)

write.csv(ward_exposure, file.path(d_data,"derived", "ward_qoz_exposure.csv"), row.names = FALSE)


#-------------------------------------------------------------------------------
#NYC
#-------------------------------------------------------------------------------
#Load in Tracts
tracts_nyc =st_read(file.path(d_data,"raw/shapefiles/tracts_2010_nyc", "tracts_2010_nyc.shp"))
tracts_nyc  =st_transform(tracts_nyc , crs = 4326)

#Adding State and County Codes
#Manhattan 061 
#BK 047
#Queens 081
#BX 005
#SI 085

# Correspondence between borough names and state/county codes
correspondence <- data.frame(boro_name = c("Bronx", "Brooklyn", "Manhattan", "Queens", "Staten Island"),
                             state_code = c("36", "36", "36", "36", "36"),
                             county_code = c("005", "047", "061", "081", "085"))
tracts_nyc_code <- left_join(tracts_nyc, correspondence, by = "boro_name")
tracts_nyc_code = tracts_nyc_code %>%
  mutate(geoid = paste0(state_code, county_code, ct2010))
tracts_nyc_final = tracts_nyc_code %>%
  select(geoid, geometry)


#Load in Census Tracts
acs =  read.csv(file.path(d_data,"raw/opp_zones/acs2011_2015/nhgis0018_csv", "nhgis0018_ds216_20155_tract.csv"))

acs = acs %>%
  mutate(geoid = substr(GEOID, 8,19))%>%
  mutate(poverty = AD2DE002/AD2DE001)%>%
  mutate(med_faminc = AD4LE001)%>%
  select(geoid, med_faminc, poverty)

#merge with ACS
tracts_acs = left_join(tracts_nyc_final, acs, by = "geoid")

#merge with Opp Zone
tracts_oppzone = left_join(tracts_acs, qozs, by = "geoid")
tracts_oppzone = tracts_oppzone %>%
  mutate(qoz  = ifelse(is.na(qoz), 0,qoz))

#Load in City Council
nycc=  st_read(file.path(d_data,"raw/shapefiles/nycc_23d", "nycc.shp"))
nycc =st_transform(nycc, crs = 4326)
nycc = nycc %>%
  select(district = CounDist)
nycc$dist_area <- st_area(nycc)

intersect_tracts_nycc = st_intersection(nycc, tracts_oppzone)
intersect_tracts_nycc$intersect_area <- st_area(intersect_tracts_nycc)

#Intersecting with Wards
intersect_tracts_nycc = intersect_tracts_nycc %>%
  mutate(frac_dist = as.numeric(intersect_area/dist_area)) %>%
  mutate(district = as.numeric(district))

#Computing Exposure 
intersect_tracts_nycc_collapse <- intersect_tracts_nycc %>%
  group_by(district) %>%
  summarize(frac_qoz = weighted.mean(qoz, w = frac_dist),
            med_faminc = weighted.mean(med_faminc, w = frac_dist),
            poverty = weighted.mean(poverty, w = frac_dist))

#Exporting
dist_exposure = intersect_tracts_nycc_collapse  %>%
  select(district, frac_qoz)%>%
  as.data.frame() %>%
  select(-geometry)

write.csv(dist_exposure, file.path(d_data,"derived", "nyc_qoz_exposure.csv"), row.names = FALSE)


