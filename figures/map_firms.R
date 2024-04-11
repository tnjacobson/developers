#Mapping Spatial Concentration

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


#Load in City Council Districts
nycc=  st_read(file.path(d_data,"raw/shapefiles/nycc_23d", "nycc.shp"))
nycc =st_transform(nycc, crs = 4326)
nycc = nycc %>%
  select(district = CounDist)
nycc$dist_area <- st_area(nycc)

#Loading in Stata Dataset for Housing
housing =   read.csv(file.path(d_data,"derived/nyc", "dob_permits_firm_ids_units.csv"))
housing = housing %>% 
          filter(!is.na(latitude))
housing_sf <- st_as_sf(housing, coords = c("longitude", "latitude"), crs = 4326)

#Filtering 
housing_rabsky = housing_sf %>%
    filter(firm == "2124213535") %>%
  filter(proposeddwellingunits >= 10)

housing_rabsky_large = housing_sf %>%
  filter(firm == "2124213535") %>%
  filter(proposeddwellingunits >= 10)

housing_chetrit = housing_sf %>%
  filter(firm == "6462309360") %>%
  filter(proposeddwellingunits >= 10)

housing_related = housing_sf %>%
  filter(firm == "2124215332")%>%
  filter(proposeddwellingunits >= 10)

housing_extell = housing_sf %>%
  filter(firm == "2127126000")%>%
  filter(proposeddwellingunits >= 10)

#Mapping


# Assuming `library(ggplot2)` and `library(sf)` are already loaded

# List of datasets to loop through
housing_datasets <- list(
  housing_related = housing_related,
  housing_chetrit = housing_chetrit,
  housing_extell = housing_extell,
  housing_rabsky = housing_rabsky
)

# Loop through each dataset and create a map
for (dataset_name in names(housing_datasets)) {
  # Extract the current dataset
  current_dataset <- housing_datasets[[dataset_name]]
  
# Create the map
  map <- ggplot() +
    geom_sf(data = nycc, color = "navy", fill = "white") +
    geom_sf(data = current_dataset, color = "maroon", size = 3, alpha = 0.7) +
    coord_sf(xlim = c(-74.05, -73.85),
             ylim = c(40.68, 40.8),
             expand = FALSE) +
    theme_minimal() +
    theme(
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      axis.text.x = element_blank(),
      axis.text.y = element_blank(),
      axis.ticks = element_blank(),
      axis.title.x = element_blank(),
      axis.title.y = element_blank()
    )
  
  # Export the map to a PDF file
  pdf_filename <- paste0("map_", dataset_name, ".pdf")
  ggsave(file.path("/Users/tylerjacobson/Dropbox/development/figures/nyc",pdf_filename), map, width = 11, height = 8.5)
}

