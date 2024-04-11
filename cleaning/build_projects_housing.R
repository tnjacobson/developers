#Build Projects Data

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
#Prepping Geography Data
#-------------------------------------------------------------------------------
parcels <- fread(file.path(d_data,"raw/assessor_cc", "parcel_universe_2023.csv"))
parcels = parcels %>%
          select(pin, pin10, latitude, longitude, census_tract_geoid)
check_coverage(parcels)

parcels10 = parcels %>%
  group_by(pin10) %>%
  slice(1) %>%
  ungroup()
#-------------------------------------------------------------------------------
#Commercial Data
#-------------------------------------------------------------------------------
#Load in Commercial Data
commercial <- fread(file.path(d_data,"raw/assessor_cc", "commercial.csv"))

#Cleaning Up Variables We Need 
commercial = commercial %>%
              select(keypin, pins, township, tax_year = year, 'class(es)', studiounits, '1brunits', 
                    '2brunits', '3brunits', '4brunits', tot_units, address,
                     rent_sf = `adj_rent/sf`, bldgsf, finalmarketvalue, `property_type/use`,
                     reportedoccupancy, vacancy, yearbuilt, owner)

#Separate pins 
commercial$pins_list <- strsplit(commercial$'pins', split = ",")
commercial$pins_list_length <- sapply(commercial$pins_list, length)

#Separate classes into different columns
commercial$classes_list <- strsplit(commercial$'class(es)', split = ",")
commercial$classes_list_length <- sapply(commercial$classes_list, length)

commercial$pin_class_match = as.integer(commercial$pins_list_length == commercial$classes_list_length)
mean(commercial$pin_class_match)

max_length = max(commercial$classes_list_length)

# Create the 'residential' variable
commercial$residential <- sapply(commercial$classes_list, function(lst) {
  # Check if any element in the list starts with '3' or '9'
  any(grepl("^3", lst) | grepl("^9", lst))
})

# Convert the logical values (TRUE/FALSE) to binary (1/0)
commercial$residential <- as.integer(commercial$residential)

#Keeping just residential properties 
commercial_res = commercial %>%
                  filter(residential == 1) 

#Cleaning Up Units
commercial_res = commercial_res %>%
  mutate(
    total_units = coalesce(`studiounits`, 0) + coalesce(`1brunits`, 0) + coalesce(`2brunits`, 0) +
      coalesce(`3brunits`, 0) + coalesce(`4brunits`, 0)
  )%>%
  mutate(units = pmax(total_units, coalesce(`tot_units`, 0)))%>%
  select(-total_units, -tot_units, -studiounits, -`1brunits`, -`2brunits`, 
         -`3brunits`, -`4brunits`)

#Merging in LAT/LON 
commercial_res = commercial_res %>%
                  mutate(keypin = str_replace_all(keypin, "-",""))

commercial_res_join = left_join(commercial_res, parcels, by = c('keypin' = 'pin'))%>%
  mutate(data_origin = "commercial")


#-------------------------------------------------------------------------------
#Improvements Data
#-------------------------------------------------------------------------------
improvements = fread(file.path(d_data,"raw/assessor_cc", "improvements_2023.csv"))
improvements = improvements %>%
                select(pin, class, year_built, building_sqft, land_sqft, num_apartments, recent_renovation)
# Define a mapping from text to numeric
number_mapping <- c("None" = 1, "Two" = 2, "Three" = 3, "Four" = 4, "Five" = 5, "Six" = 6, "Seven" = 7)

# Use mutate and the mapping to create the "units" column
improvements <- improvements %>%
  mutate(units = number_mapping[num_apartments])

#Merge on Geography
improvements = improvements %>%
  mutate(pin = stringr::str_pad(pin, width = 14, side = "left", pad = "0"))

improvements_join = left_join(improvements, parcels, by = c('pin' = 'pin'))%>%
  mutate(data_origin = "improvements")


#-------------------------------------------------------------------------------
#Condos Data
#-------------------------------------------------------------------------------
condos = fread(file.path(d_data,"raw/assessor_cc", "condos_2023.csv"))

#Collapsing Down to Pin
condos10 = condos %>%
  group_by(pin10) %>%
  summarize(
    units = n(),
    year_built_max_condos = max(year_built, na.rm = TRUE),
    year_built = min(year_built, na.rm = TRUE),
    land_sqft = max(land_sqft, na.rm = TRUE),
    class = min(class, na.rm = TRUE)
  )

#condos10_check = condos10 %>%
#    mutate(gap_land = max_land_sqft - min_land_sqft)%>%
#  mutate(gap_year = max_year_built - min_year_built)

#condos10_check = condos10_check  %>%
#  mutate(pin10 = stringr::str_pad(pin10, width = 10, side = "left", pad = "0"))
#condos10_join = left_join(condos10_check, parcels10, by = c('pin10' = 'pin10'))

condos10 = condos10 %>%
  mutate(pin10 = stringr::str_pad(pin10, width = 10, side = "left", pad = "0"))
condos10_join = left_join(condos10, parcels10, by = c('pin10' = 'pin10'))

condos10_join = condos10_join %>%
  mutate(data_origin = "condos")

#-------------------------------------------------------------------------------
#Appending into Single Projects Based
#-------------------------------------------------------------------------------
commercial_final = commercial_res_join %>%
  mutate(land_sqft = NA) %>%
  select(pin = keypin, bldg_sqft = bldgsf, land_sqft, 
         year_built = yearbuilt, units, latitude, longitude, data_origin)

condos10_final = condos10_join  %>%
  mutate(bldg_sqft = NA) %>%
  select(pin, bldg_sqft, land_sqft, 
         year_built, units, latitude, longitude, data_origin)

improvements_final = improvements_join  %>%
  mutate(bldg_sqft = NA) %>%
  select(pin, bldg_sqft = building_sqft, land_sqft, 
         year_built, units, latitude, longitude, data_origin)


housing = rbind(condos10_final, improvements_final, commercial_final)

#-------------------------------------------------------------------------------
#Linking with Zoning Data 
#-------------------------------------------------------------------------------
#Load in Maps
zoning2023 <- st_read(file.path(d_data,"raw/zoning_nov23", "Zoning_asof_14NOV2023.shp"))
zoning2023 =st_transform(zoning2023, crs = 4326)
zoning2023 = st_make_valid(zoning2023)
zoning2023 = zoning2023 %>%
            select(zone_class2023 = ZONE_CLASS, recent_map_change2023 = ORDINANCE1)

zoning2012 <- st_read(file.path(d_data,"raw/Zoning 2012", "Zoning_nov2012.shp"))
zoning2012 =st_transform(zoning2012, crs = 4326)
zoning2012 = st_make_valid(zoning2012)
zoning2012 = zoning2012 %>%
  select(zone_class2012 = ZONE_CLASS)


changes <- st_read(file.path(d_data,"derived/rezoning/zoning_changes.shp"))

#Convert Housing into a Shapefile
housing_sf <- housing %>%
              filter(!is.na(latitude))%>%
              st_as_sf( coords = c("longitude", "latitude"), crs = 4326) 

housing_sf_join = st_join(housing_sf, zoning2023)
housing_sf_join = st_join(housing_sf_join, zoning2012)
housing_sf_chicago = housing_sf_join %>%
  filter(!is.na(zone_class2023))

#-------------------------------------------------------------------------------
#Other Geographic Merges
#-------------------------------------------------------------------------------
#Load in Wards and Tracts
wards_2015 =  st_read(file.path(d_data,"raw/shapefiles/wards_2015", "wards_2015.shp"))
wards_2015 =st_transform(wards_2015, crs = 4326)
wards_2015 = wards_2015 %>%
    select(ward2015 = ward)

wards_2003 =  st_read(file.path(d_data,"raw/shapefiles/wards_2003", "wards_2003.shp"))
wards_2003 =st_transform(wards_2003, crs = 4326)
wards_2003 = wards_2003 %>%
  select(ward2003 = ward)

housing_sf_chicago_ward = st_join(housing_sf_chicago, wards_2003)
housing_sf_chicago_ward = st_join(housing_sf_chicago_ward, wards_2015)


tracts =st_read(file.path(d_data,"raw/shapefiles/tracts_2010", "tracts_2010.shp"))
tracts =st_transform(tracts, crs = 4326)
tracts = tracts %>%
    select(tract = tractce10)

housing_sf_chicago_tract = st_join(housing_sf_chicago_ward, tracts)


#-------------------------------------------------------------------------------
#Exporting and Collapse to Ward Year
#-------------------------------------------------------------------------------
housing_export = as.data.frame(housing_sf_chicago_tract)%>%
  select(-geometry)
# housing_export is your data frame
write.csv(housing_export, file.path(d_data,"derived/housing", "housing_construction.csv"), row.names = FALSE)

#-------------------------------------------------------------------------------
#Export for Andie 
#-------------------------------------------------------------------------------
commercial_river_forest = commercial_res_join %>%
    filter(township == "River Forest")%>%
  select(-classes_list, -pins_list)
write.csv(commercial_river_forest, file.path(d_data,"derived/housing", "commercial_river_forest.csv"), row.names = FALSE)

improvements_join_rf = improvements_join %>%
  filter(census_tract_geoid==17031811900 | census_tract_geoid==17031812000)%>%
  filter(year_built >= 2005)
write.csv(improvements_join_rf, file.path(d_data,"derived/housing", "improvements_river_forest.csv"), row.names = FALSE)

condos_rf = condos10_join%>%
  filter(census_tract_geoid==17031811900 | census_tract_geoid==17031812000)%>%
  filter(year_built >= 2005)

write.csv(condos_rf, file.path(d_data,"derived/housing", "condos_river_forest.csv"), row.names = FALSE)




