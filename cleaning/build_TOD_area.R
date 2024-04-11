#Prepare Shapefile for TOD Analysis

#Setting Paths
source(file.path(Sys.getenv("HOME"),"Documents/Github/developers","prelim.R"))
source(file.path(Sys.getenv("HOME"),"Documents/Github/developers","macros/functions.R"))

library(data.table)
library(tidyverse)
library(pdftools)
library(stringr)
library(dplyr)
library(tesseract)
library(magick)
library(tidygeocoder)
library(osmdata)


#-------------------------------------------------------------------------------
#Load in Shapefiles for Stations and Pedestrian Streets
#-------------------------------------------------------------------------------
# Read the shapefiles and set the CRS to WGS 84 (EPSG:4326)
cta <- st_read(file.path(d_data, "raw/shapefiles/CTA_RailStations", "CTA_RailStations.shp")) %>%
  st_transform(4326)
metra <- st_read(file.path(d_data, "raw/shapefiles/Metra_Stations", "MetraStations.shp")) %>%
  st_transform(4326)
ped_streets <- st_read(file.path(d_data, "raw/shapefiles/Pedestrian Streets", "ped_streets.shp")) %>%
  st_transform(4326)

# Add a column with the dataset name to each shapefile
cta <- cta %>%
  mutate(dataset_name = "cta")
metra <- metra %>%
  mutate(dataset_name = "metra")
ped_streets <- ped_streets %>%
  mutate(dataset_name = "ped_streets")

# Keep only the geometry column and the new dataset_name column
cta <- cta %>%
  select(geometry, dataset_name)
metra <- metra %>%
  select(geometry, dataset_name)

# Define the buffer distance in feet (600 feet)
buffer_distance_ft <- 600

# Convert the buffer distance from feet to meters (1 foot = 0.3048 meters)
buffer_distance_m <- buffer_distance_ft * 0.3048

# Create a new geometry column with the 600ft buffer around the points
cta_buffer <- cta %>%
  st_buffer(dist = buffer_distance_m)
metra_buffer <- metra %>%
  st_buffer(dist = buffer_distance_m)

combined_buffers <- rbind(cta_buffer, metra_buffer)
combined <- rbind(cta, metra)

#-------------------------------------------------------------------------------
#Working with Pedstreets
#-------------------------------------------------------------------------------

# Define the buffer distance in feet (1200 feet)
buffer_distance_ft <- 1200

# Convert the buffer distance from feet to meters (1 foot = 0.3048 meters)
buffer_distance_m <- buffer_distance_ft * 0.3048

# Create a buffer around the points in the 'combined' dataset
combined_buffer_ped <- combined %>%
  st_buffer(dist = buffer_distance_m)

# Use st_intersects to find which lines intersect with the buffer
lines_within_buffer <- ped_streets %>%
  st_intersection(combined_buffer_ped)

# Filter only the parts of the lines that intersect with the buffer
lines_within_buffer <- lines_within_buffer[!is.na(lines_within_buffer$geometry), ]


#-------------------------------------------------------------------------------
#Mapping
#-------------------------------------------------------------------------------
# Create a base plot
p <- ggplot() +
  theme_minimal() 
# Add the buffer polygons to the plot
p <- p +
  geom_sf(data = combined_shapefile, aes(fill = "Steel Blue"), color = "black", size = 1)
# Set the coordinate limits
p <- p +
  coord_sf(xlim = x, ylim = y, expand = FALSE)
print(p)


+
  geom_sf(data = polygon_sf, aes(fill = "Steel Blue"), color = "black", size = 1)


#Plotting PLanned Development Status in 2023
map_pdcurrent=ggplot() +
  geom_sf(data = mapping_current, aes(fill = factor(PD, labels = c("No", "Yes")))) +
  coord_sf(xlim = x,
           ylim = y,
           expand = FALSE) +
  theme_minimal() +
  theme(panel.grid = element_blank(),  # Remove gridlines
        axis.text.x = element_blank(),  # Remove x-axis labels
        axis.text.y = element_blank(),  # Remove y-axis labels
        axis.title.x = element_blank(), # Remove x-axis title
        axis.title.y = element_blank(), # Remove y-axis title
        legend.position = c(0.08, 0.2)) +
  scale_fill_discrete(name = "PD in 2023")


metra <- metra %>%
  select(geometry, dataset_name)
ped_streets <- ped_streets %>%
  select(geometry, dataset_name)

combined_shapefile <- rbind(cta, metra, ped_streets)

#-------------------------------------------------------------------------------
#Make a map
#-------------------------------------------------------------------------------
#Bounding Box for Chicago
x=c(-87.9403, -87.5241)
y=c(41.6445, 42.0230)

#Bounding Box for North
xn=c(-87.8, -87.6)
yn=c(41.85, 41.95)

library(ggplot2)

# Assuming you have already loaded and prepared the shapefiles as described previously

# Create a base plot
p <- ggplot() +
  scale_fill_manual(values = c("cta" = "red", "metra" = "blue", "ped_streets" = "green")) +
  theme_minimal() +
  labs(fill = "Layers")

# Add point layers for 'cta' and 'metra' stations
p <- p +
  geom_sf(data = cta, aes(fill = "cta"), shape = 21, size = 3) +
  geom_sf(data = metra, aes(fill = "metra"), shape = 23, size = 3)

# Add a line layer for 'ped_streets'
p <- p +
  geom_sf(data = ped_streets, aes(fill = "ped_streets"), size = 1)

# Set the coordinate limits
p <- p +
  coord_sf(xlim = x, ylim = y, expand = FALSE)

# Print the plot
print(p)


