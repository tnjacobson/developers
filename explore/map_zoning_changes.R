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
#Load Zoning Maps
#-------------------------------------------------------------------------------
zoning2023 <- st_read(file.path(d_data,"raw/zoning_nov23", "Zoning_asof_14NOV2023.shp"))
zoning2023 =st_transform(zoning2023, crs = 4326)
zoning2023 = st_make_valid(zoning2023)

zoning2012 <- st_read(file.path(d_data,"raw/Zoning 2012", "Zoning_nov2012.shp"))
zoning2012 =st_transform(zoning2012, crs = 4326)
zoning2012 = st_make_valid(zoning2012)

changes <- st_read( file.path(d_data,"derived/rezoning/zoning_changes.shp"))



#Bounding Box for Chicago
x=c(-87.9403, -87.5241)
y=c(41.6445, 42.0230)

#Bounding Box for North
xn=c(-87.8, -87.6)
yn=c(41.85, 41.95)

#Plotting PLanned Development Status in 2012
map_changes=ggplot() +
  geom_sf(data = changes) +
  coord_sf(xlim = x,
           ylim = y,
           expand = FALSE) +
  theme_minimal() 

map_changes




+
  theme(panel.grid = element_blank(),  # Remove gridlines
        axis.text.x = element_blank(),  # Remove x-axis labels
        axis.text.y = element_blank(),  # Remove y-axis labels
        axis.title.x = element_blank(), # Remove x-axis title
        axis.title.y = element_blank(), # Remove y-axis title
        legend.position = c(0.08, 0.2)) +
  scale_fill_discrete(name = "PD in 2012")
ggsave(map_pd2012, file=file.path(figures,"rezoning/maps/map_pd2012.pdf"))
