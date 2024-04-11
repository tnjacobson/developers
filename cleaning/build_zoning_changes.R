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

#-------------------------------------------------------------------------------
#Load in the List of Changes and Geocode
#-------------------------------------------------------------------------------

# Function to check if string looks like an address
is_address <- function(address) {
  grepl("^[0-9]+\\s+(N|S|E|W)?\\s*\\b[A-Za-z]+\\s+(St|Ave|Blvd|Rd|Lane|Way|Drive|Dr|Court|Ct|Place|Pl)$", address)
}

ordinances <- fread(file.path(d_data,"raw/rezoning", "chicago_clerk_zoning_matters.csv"))

# Regular expression to extract text between "at" and "- App"
pattern <- "at\\s(.*?)\\s-\\sApp"

# Applying the regex to each row in the 'Title' column
ordinances <- ordinances %>%
  mutate(address = str_extract(Title, pattern) %>%
           str_replace_all("at\\s|\\s-\\sApp", ""))

# Separate out the completed address
ordinances_complete = ordinances %>%
  filter(!is.na(address))

ordinances_missing = ordinances %>%
    filter(is.na(address))

ordinances_missing <- ordinances_missing %>%
  mutate(address = sub(".*at ", "", Title))


# Add a new column to the dataframe
ordinances_missing_short <- ordinances_missing %>%
  mutate(looks_like_address = sapply(address, is_address))%>%
  select(address)

#Save problematic addresses
write.csv(ordinances_missing_short, file.path(d_data,"raw/rezoning", "temp_addresses.csv"))

#Load in the addresses processed using GPT
gpt <- fread(file.path(d_data,"raw/rezoning", "temp_addresses_gpt.csv"))
ordinances_missing$address = gpt$cleaned_address

#Append
all_ordinances <- bind_rows(ordinances_missing, ordinances_complete)%>%
  mutate(address = paste0(address, " Chicago, IL"))
write.csv(all_ordinances, file.path(d_data,"raw/rezoning", "all_ordinances.csv"))


#Load in Geocoded Addresses from ESRI
ordinances_gis <- st_read(file.path(d_data,"intermediate/ordinances_arcgis", "all_ordinances2.shp"))
ordinances_gis =st_transform(ordinances_gis, crs = 4326)


#-------------------------------------------------------------------------------
#Intersect with 2023 Map to Get Geometry and New Zoning Type
#-------------------------------------------------------------------------------
map <- st_read(file.path(d_data,"raw/zoning_nov23", "Zoning_asof_14NOV2023.shp"))
map =st_transform(map, crs = 4326)
map = st_make_valid(map)

ordinances_gis_join <- st_join(ordinances_gis, map)

#Saving for Exploration in Stata
ordinances_gis_join_export = ordinances_gis_join %>%
                              as.data.frame()%>%
                              select(-geometry)
write.csv(ordinances_gis_join_export, file.path(d_data,"intermediate", "test_join.csv"))

#Cleaning 
names(ordinances_gis_join) = tolower(names(ordinances_gis_join))
ordinances_gis_join_cleaned = ordinances_gis_join %>%
                mutate(lon_clerk = st_coordinates(geometry)[, 1],
                        lat_clerk = st_coordinates(geometry)[, 2])%>%
                      rename(record_clerk = record__, zone_class_post = zone_class, final_date_clerk = final_date,
                            final_date_map = ordinance1, ordinance_map = clerk_docn, objectid_post = objectid) %>%
                      select(-legacy__, -filing_off, -type, -controllig, -zoning_id, -create_tim, -create_use, -update_use,
                             -pmd_sub_ar, -override_r, -override_c, -globalid, -shape_area, -shape_len)



#-------------------------------------------------------------------------------
#Intersect with 2012 Map to Get Past Zoning Type
#-------------------------------------------------------------------------------
#Adding Tract 
#Load in Tracts
tracts =st_read(file.path(d_data,"raw/shapefiles/tracts_2010", "tracts_2010.shp"))
tracts =st_transform(tracts, crs = 4326)
tracts = tracts %>%
  select(tract = geoid10)

zoning2012 <- st_read(file.path(d_data,"raw/Zoning 2012", "Zoning_nov2012.shp"))
zoning2012 =st_transform(zoning2012, crs = 4326)
zoning2012 = st_make_valid(zoning2012)

ordinances_gis_join_pre <- st_join(ordinances_gis_join_cleaned, zoning2012%>%select(zone_class_pre = ZONE_CLASS))
ordinances_gis_join_pre <- st_join(ordinances_gis_join_pre, tracts)

ordinances_gis_join_pre = ordinances_gis_join_pre %>%
  as.data.frame() %>%
  select(-geometry)

write.csv(ordinances_gis_join_pre, file.path(d_data,"derived/rezoning", "zoning_changes.csv"))

ordinances_final = left_join(ordinances_gis_join_pre, map%>%select(OBJECTID, geometry), by=c("objectid_post" = "OBJECTID"))                   

st_write(ordinances_final, file.path(d_data,"derived/rezoning/zoning_changes.shp"), append= FALSE)


