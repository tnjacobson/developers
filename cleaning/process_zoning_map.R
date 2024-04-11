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
zoning2012 <- st_read(file.path(d_data,"raw/Zoning 2012", "Zoning_nov2012.shp"))
zoning2012 =st_transform(zoning2012, crs = 4326)
zoning2012 = st_make_valid(zoning2012)

zoningcurrent <- st_read(file.path(d_data,"raw/zoning_nov23", "Zoning_asof_14NOV2023.shp"))
zoningcurrent =st_transform(zoningcurrent, crs = 4326)
zoningcurrent = st_make_valid(zoningcurrent)


#Loading Qualities
class_qualities <- fread(file.path(d_data,"raw/secondcityzoning", "zoning-code-summary-district-types.csv"))%>%
                  mutate(log_floor_area_ratio = log(as.numeric(floor_area_ratio)))


# Merge and rename for zoning2012
zoning2012_merge <- zoning2012 %>%
  left_join(class_qualities, by = c("ZONE_CLASS" = "district_type_code")) %>%
  mutate(FAR_2012 = as.numeric(floor_area_ratio))

# Merge and rename for zoningcurrent
zoningcurrent_merge <- zoningcurrent %>%
  left_join(class_qualities, by = c("ZONE_CLASS" = "district_type_code")) %>%
  mutate(FAR_current = as.numeric(floor_area_ratio))

#-------------------------------------------------------------------------------
#Add Census Tract
#-------------------------------------------------------------------------------

# Step 1: Load the 2010 Tract Shapefile for Cook County, IL
chicago_tracts <- st_read(file.path(d_data,"raw/shapefiles/tracts_2010", "tracts_2010.shp"))

# Step 2: Transform and make valid the cook_county_tracts data
chicago_tracts <- st_transform(chicago_tracts, crs = 4326)
chicago_tracts <- st_make_valid(chicago_tracts)
chicago_tracts <- st_simplify(chicago_tracts)

#Merge with zoning
zoningcurrent_merge_simple = st_simplify(zoningcurrent_merge)
zoning2012_merge_simple = st_simplify(zoning2012_merge)

#Try Intersection
intersection_current <- st_intersection_faster(chicago_tracts, zoningcurrent_merge_simple)

#intersection_2012 <- st_intersection_faster(chicago_tracts, zoning2012_merge_simple)
driver <- "ESRI Shapefile"


saveRDS(intersection_current,file.path(d_data,"intermediate/shapefiles", "intersection_current.RDS"))
saveRDS(intersection_2012,file.path(d_data,"intermediate/shapefiles", "intersection_2012.RDS"))

st_write(intersection_current, dsn = file.path(d_data,"intermediate/shapefiles", "intersection_current"), driver = driver)
st_write(intersection_2012, dsn = file.path(d_data,"intermediate/shapefiles", "intersection_2012"), driver = driver)

#-------------------------------------------------------------------------------
#Add Census Tract
#-------------------------------------------------------------------------------

zoning2012_group = zoning2012 %>%
  group_by(ZONE_CLASS) %>%
  summarize(geometry = st_union(geometry))
zoning2012_group =st_transform(zoning2012_group, crs = 4326)
zoning2012_group = st_make_valid(zoning2012_group)

zoningcurrent_group = zoningcurrent%>%
  group_by(zone_class) %>%
  summarize(geometry = st_union(geometry))
zoningcurrent_group =st_transform(zoningcurrent_group, crs = 4326)
zoningcurrent_group = st_make_valid(zoningcurrent_group)

intersection = st_intersection(zoning2012_group, zoningcurrent_group)


#-------------------------------------------------------------------------------
#Prepping Map
#-------------------------------------------------------------------------------
#Getting Streets 
big_streets <- getbb("Chicago United States")%>%
  opq()%>%
  add_osm_feature(key = "highway", 
                  value = c("motorway", "primary", "motorway_link", "primary_link")) %>%
  osmdata_sf()


#Get River 
river <- getbb("Chicago United States")%>%
  opq()%>%
  add_osm_feature(key = "waterway", value = "river") %>%
  osmdata_sf()

#-------------------------------------------------------------------------------
#Basic Descriptives
#-------------------------------------------------------------------------------
mapping_2012 = zoning2012_merge %>%
        mutate(PD = PD_NUM!=0)
mapping_current = zoningcurrent_merge %>%
  mutate(PD = pd_num!=0)

#Bounding Box for Chicago
x=c(-87.9403, -87.5241)
y=c(41.6445, 42.0230)

#Bounding Box for North
xn=c(-87.8, -87.6)
yn=c(41.85, 41.95)

#Plotting PLanned Development Status in 2012
map_pd2012=ggplot() +
  geom_sf(data = mapping_2012, aes(fill = factor(PD, labels = c("No", "Yes")))) +
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
  scale_fill_discrete(name = "PD in 2012")
ggsave(map_pd2012, file=file.path(figures,"rezoning/maps/map_pd2012.pdf"))

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
ggsave(map_pdcurrent, file=file.path(figures,"rezoning/maps/map_pdcurrent.pdf"))

#Zooming in on 2012 PD
map_pd2012_zoom = ggplot() +
  geom_sf(data = mapping_2012, aes(fill = factor(PD, labels = c("No", "Yes")))) +
  coord_sf(xlim = xn,
           ylim = yn,
           expand = FALSE) +
  theme_minimal() +
  theme(panel.grid = element_blank(),  # Remove gridlines
        axis.text.x = element_blank(),  # Remove x-axis labels
        axis.text.y = element_blank(),  # Remove y-axis labels
        axis.title.x = element_blank(), # Remove x-axis title
        axis.title.y = element_blank(), # Remove y-axis title
        legend.position = c(0.08, 0.2), # Adjust legend position
        legend.background = element_rect(fill = "white", color = "black")) +
  scale_fill_discrete(name = "PD in 2012")
ggsave(map_pd2012_zoom, file=file.path(figures,"rezoning/maps/map_pd2012_zoom.pdf"))

#Zooming in on 2023
map_pdcurrent_zoom = ggplot() +
  geom_sf(data = mapping_current, aes(fill = factor(PD, labels = c("No", "Yes")))) +
  coord_sf(xlim = xn,
           ylim = yn,
           expand = FALSE) +
  theme_minimal() +
  theme(panel.grid = element_blank(),  # Remove gridlines
        axis.text.x = element_blank(),  # Remove x-axis labels
        axis.text.y = element_blank(),  # Remove y-axis labels
        axis.title.x = element_blank(), # Remove x-axis title
        axis.title.y = element_blank(), # Remove y-axis title
        legend.position = c(0.08, 0.2), # Adjust legend position
        legend.background = element_rect(fill = "white", color = "black")) +
  scale_fill_discrete(name = "PD in 2023")
ggsave(map_pdcurrent_zoom, file=file.path(figures,"rezoning/maps/map_pdcurrent_zoom.pdf"))

#-------------------------------------------------------------------------------
#Working with Tract Maps
#-------------------------------------------------------------------------------



# Load the required packages
library(tigris)  # For loading Census data
library(sf)      # For spatial operations

# Step 1: Load the 2010 Tract Shapefile for Cook County, IL
cook_county_tracts <- tigris::tracts(state = "IL", county = "Cook", year = 2010)

# Step 2: Transform and make valid the cook_county_tracts data
cook_county_tracts <- st_transform(cook_county_tracts, crs = 4326)
cook_county_tracts <- st_make_valid(cook_county_tracts)

# Step 4: Perform the spatial intersection
intersection_current <- st_intersection_faster(cook_county_tracts, zoningcurrent_merge)
intersection_2012 <- st_intersection(cook_county_tracts, zoning2012_merge)

# Calculate the area of each intersected polygon (assuming it's in square meters)
intersection_result <- intersection_result %>%
  mutate(area = st_area(.))%>%
  mutate(PD = pd_num!=0)

# Group by tract and calculate the weighted average of "current_FAR" and "PD"
collapse <- intersection_result %>%
  group_by(TRACTCE10) %>%
  summarize(
    weighted_avg_FAR = sum(current_FAR * area) / sum(area),
    weighted_avg_PD = sum(PD * area) / sum(area)
  )

# Create the map
map_weighted_avg_PD <- ggplot(result) +
  geom_sf(aes(fill = factor(weighted_avg_PD > 0, labels = c("No", "Yes")))) + # You can adjust the labels as needed
  theme_minimal() +
  theme(panel.grid = element_blank(),          # Remove gridlines
        axis.text.x = element_blank(),        # Remove x-axis labels
        axis.text.y = element_blank(),        # Remove y-axis labels
        axis.title.x = element_blank(),       # Remove x-axis title
        axis.title.y = element_blank(),       # Remove y-axis title
        legend.position = c(0.08, 0.2),      # Adjust legend position
        legend.background = element_rect(fill = "white", color = "black")) +
  scale_fill_discrete(name = "Weighted Avg PD")

# Save the map as a PDF
ggsave(map_weighted_avg_PD, file = file.path(figures, "rezoning/maps/map_weighted_avg_PD.pdf"))


#-------------------------------------------------------------------------------
#Mapping Intersection Data
#-------------------------------------------------------------------------------
#Adding in Floor Area Ratios
merged_intersection <- intersection %>%
  left_join(class_qualities, by = c("ZONE_CLASS" = "district_type_code"))%>%
  mutate(FAR_2012 = as.numeric(floor_area_ratio))%>%
  select(-floor_area_ratio)
merged_intersection <- merged_intersection %>%
  left_join(class_qualities, by = c("zone_class" = "district_type_code"))%>%
  mutate(FAR_current = as.numeric(floor_area_ratio))%>%
  mutate(ch_FAR = FAR_current/FAR_2012 - 1 )%>%
  mutate(ch_FAR_w = ifelse(ch_FAR > 1, 1, ch_FAR)) %>%
  select(-floor_area_ratio)

#Actually Mapping
map_whole = ggplot() +
  geom_sf(data = river$osm_lines,
          inherit.aes = FALSE,
          color = "steelblue")+
  geom_sf(data = big_streets$osm_lines,
          inherit.aes = FALSE,
          color = "gray",
          size = .3,
          alpha = .5)   +
  geom_sf(data = merged_intersection, aes(fill = ch_FAR_w)) +
  coord_sf(xlim = x, 
           ylim = y,
           expand = FALSE) +
  theme_minimal() 
ggsave(map_whole, file=file.path(figures,"rezoning/maps/map_ch_FAR.pdf"))


geom_sf(data = merged_intersection, aes(fill = ch_FAR)) +
  scale_fill_gradient2(low = "red", mid = "white", high = "blue", midpoint = 0) 

#-------------------------------------------------------------------------------
#Some Basic Maps
#-------------------------------------------------------------------------------
ggplot(data = zoning2012_merge) +
  geom_sf(aes(fill = log_floor_area_ratio)) +
  labs(fill = "Floor Area Ratio", 
       title = "Map of Floor Area Ratio") +
  theme_minimal()