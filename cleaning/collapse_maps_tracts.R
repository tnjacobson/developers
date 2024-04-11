#Zoning Map Analysis

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

#load in intersection:
sf_current = readRDS(file.path(d_data,"intermediate/shapefiles", "intersection_current.RDS"))
sf_2012= readRDS(file.path(d_data,"intermediate/shapefiles", "intersection_2012.RDS"))

#Variables to sum:
#floor area ratio, single family status, share of developable land

#Collapsing 
sf_current_fix = st_make_valid(sf_current)
sf_current_fix = sf_current_fix%>%
            mutate(area = st_area(geometry))

current_data = sf_current_fix %>%
  as.data.frame()

collapse_current = current_data %>%
                mutate(sf_zone_current =  ifelse(substr(zone_class, 1, 2) == "RS", 1, 0))%>%
                mutate(pd_current =  ifelse(pd_num == 0, 0, 1))%>%
                group_by(tractce10) %>%
                summarize(
                    weighted_pd_current = sum(pd_current * area, na.rm = TRUE),
                    weighted_sf_zone_current = sum(sf_zone_current * area, na.rm = TRUE),
                    weighted_FAR_current = sum(FAR_current * area, na.rm = TRUE),
                    total_area = sum(area, na.rm = TRUE)
  )

#Compute the weighted averages
collapse_current <- collapse_current %>%
  mutate(
    avg_pd_current = as.numeric(weighted_pd_current / total_area),
    avg_sf_zone_current = as.numeric(weighted_sf_zone_current / total_area),
    avg_FAR_current = as.numeric(weighted_FAR_current /total_area)
  )

#-------------------------------------------------------------------------------
#2012
#-------------------------------------------------------------------------------

# Collapsing 
sf_2012_fix = st_make_valid(sf_2012)
sf_2012_fix = sf_2012_fix %>%
  mutate(area = st_area(geometry))


data_2012 = as.data.frame(sf_2012_fix)


collapse_2012 = data_2012 %>%
  mutate(sf_zone_2012 =  ifelse(substr(ZONE_CLASS, 1, 2) == "RS", 1, 0)) %>%
  mutate(pd_2012 =  ifelse(PD_NUM == 0, 0, 1)) %>%
  group_by(tractce10) %>%
  summarize(
    weighted_pd_2012 = sum(pd_2012 * area, na.rm = TRUE),
    weighted_sf_zone_2012 = sum(sf_zone_2012 * area, na.rm = TRUE),
    weighted_FAR_2012 = sum(FAR_2012 * area, na.rm = TRUE),
    total_area = sum(area, na.rm = TRUE)
  )

# Compute the weighted averages
collapse_2012 <- collapse_2012 %>%
  mutate(
    avg_pd_2012 = as.numeric( weighted_pd_2012 / total_area),
    avg_sf_zone_2012 = as.numeric(weighted_sf_zone_2012 / total_area),
    avg_FAR_2012 = as.numeric(weighted_FAR_2012 / total_area))

  collapse <- merge(collapse_2012, collapse_current, by = "tractce10")
  write.csv(collapse, file = file.path(d_data,"intermediate", "tract_zoning_map.csv"), row.names = FALSE)
  
  
  
#-------------------------------------------------------------------------------
#Mapping 
#-------------------------------------------------------------------------------
chicago_tracts <- st_read(file.path(d_data,"raw/shapefiles/tracts_2010", "tracts_2010.shp"))

# Transform and make valid the cook_county_tracts data
chicago_tracts <- st_transform(chicago_tracts, crs = 4326)
chicago_tracts <- st_make_valid(chicago_tracts)

merged_data <- merge(chicago_tracts, collapse, by = "tractce10")

merged_data = merged_data %>%
              mutate(ch_FAR = avg_FAR_current - avg_FAR_2012, 
                     ch_sf = avg_sf_zone_current - avg_sf_zone_2012, 
                     ch_pd = avg_pd_current - avg_pd_2012)

ggplot(data = merged_data) +
  geom_sf(aes(fill = avg_sf_zone_current)) +
  theme_minimal() +
  labs(fill = "Average SF Zone", title = "Map of Average SF Zone Current")

ggplot(data = merged_data) +
  geom_sf(aes(fill = as.numeric(avg_FAR_current))) +
  scale_fill_continuous(limits = c(NA, 3), oob = scales::squish) +  # Set scale limits with squish to handle out-of-bounds values
  theme_minimal() +
  labs(fill = "Average FAR Current", title = "Map of Average SF Zone Current")

ggplot(data = merged_data) +
  geom_sf(aes(fill = ch_sf)) +
  scale_fill_gradient2(low = "red", high = "blue", mid = "white", midpoint = 0, limit = c(NA, .05), oob = scales::squish) +
  theme_minimal() +
  labs(fill = "Change in SF", title = "Map of Change in SF Zone")

ggplot(data = merged_data) +
  geom_sf(aes(fill = ch_pd)) +
  scale_fill_gradient2(low = "red", high = "blue", mid = "white", midpoint = 0, oob = scales::squish) +
  theme_minimal() +
  labs(fill = "Change in SF", title = "Map of Change in SF Zone")



