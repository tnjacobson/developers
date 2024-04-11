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
library(lubridate)


zoningcurrent <- st_read(file.path(d_data,"raw/Boundaries - Zoning Districts (current) - 2016", "current_zoning.shp"))

#Loading Qualities
class_qualities <- fread(file.path(d_data,"raw/secondcityzoning", "zoning-code-summary-district-types.csv"))%>%
  mutate(floor_area_ratio = as.numeric(floor_area_ratio))

zoningcurrent = as.data.frame(zoningcurrent)%>% 
  left_join(class_qualities, by = c("zone_class" = "district_type_code")) %>%
    select(-geometry) 

tab <- zoningcurrent %>%
  group_by(date_ordin) %>%
  summarize(count = n(), 
            far = mean(floor_area_ratio, na.rm = TRUE)) %>%
  filter(date_ordin > as.Date("1999-12-31"))

ggplot(tab, aes(x = date_ordin, y = count)) +
  geom_line() + # Line plot
  labs(title = "Time Series of Counts",
       x = "Date",
       y = "Count") +
  theme_minimal() 

ggplot(tab, aes(x = date_ordin, y = far)) +
  geom_line() + # Line plot
  labs(title = "Time Series of Counts",
       x = "Date",
       y = "Count") +
  theme_minimal() 



# Calculate the weighted average of floor_area_ratio by year
tab_yearly <- zoningcurrent %>%
  mutate(year = year(date_ordin)) %>%
  group_by(year) %>%
  summarize(
    total_count = sum(n(), na.rm = TRUE),
    far = mean(floor_area_ratio, na.rm = TRUE)
  )  %>%
  filter(year > 1999)

# Create a time series plot of the weighted average FAR
ggplot(tab_yearly, aes(x = year, y = far)) +
  geom_line() + # Line plot
  labs(title = "Yearly Weighted Average FAR (Post-2000)",
       x = "Year",
       y = "Weighted Average FAR") +
  theme_minimal() # Minimal theme for a cleaner look

