#Exploring Boundaries

#Exploring RD

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


sf_use_s2(FALSE)


#Load in City Council Districts
nycc=  st_read(file.path(d_data,"raw/shapefiles/nycc_23d", "nycc.shp"))
st_crs(nycc)$units
nycc =st_transform(nycc, crs = 4326)
nycc = nycc %>%
  select(council_district = CounDist)
nycc_valid = st_make_valid(nycc)

#Loading in Stata Dataset for Housing
housing =   read.csv(file.path(d_data,"derived/nyc", "dob_permits_firm_ids_units.csv"))
housing = housing %>% 
  filter(!is.na(latitude))


#-------------------------------------------------------------------------------
#Independent of Firms
#-------------------------------------------------------------------------------

#Computing HHI in the City
housing_filter =  housing %>%
  filter(proposeddwellingunits>=10)

#Computing HHI Without Using Firm Information
district_counts <- housing_filter %>%
  group_by(council_district) %>%
  summarise(total_units = sum(proposeddwellingunits, na.rm = TRUE))

housing_filter <- housing_filter %>%
  left_join(district_counts, by = "council_district")

hhi_independent = housing_filter %>%
  mutate(district_share = ((proposeddwellingunits/total_units)*100)^2)%>%
  group_by(council_district) %>%
  summarise(hhi_independent = sum(district_share))


#-------------------------------------------------------------------------------
#With Firm Info
#-------------------------------------------------------------------------------
#Computing HHI in the City
housing_filter =  housing %>%
  filter(proposeddwellingunits>=10) %>%
  group_by(council_district, firm)%>%
  summarise(proposeddwellingunits = sum(proposeddwellingunits, na.rm = TRUE))


#Computing HHI Without Using Firm Information
district_counts <- housing_filter %>%
  group_by(council_district) %>%
  summarise(total_units = sum(proposeddwellingunits, na.rm = TRUE))

housing_filter <- housing_filter %>%
  left_join(district_counts, by = "council_district")


hhi_firms = housing_filter %>%
  mutate(district_share = ((proposeddwellingunits/total_units)*100)^2)%>%
  group_by(council_district) %>%
  summarise(hhi_firms = sum(district_share))


hhi = hhi_firms %>%
  left_join(hhi_independent, by = "council_district")


hhi = hhi %>%
  mutate(hhi_relative = hhi_firms/hhi_independent)%>%
  left_join(district_counts, by = "council_district")

#-------------------------------------------------------------------------------
#Mapping
#-------------------------------------------------------------------------------
merged =nycc_valid %>% left_join(hhi, by="council_district")

merged =  merged %>%
  mutate(hhi_firms_category = case_when(
    hhi_firms < 1500 ~ "Below 1500",
    hhi_firms >= 1500 & hhi_firms <= 2500 ~ "Between 1500 and 2500",
    hhi_firms > 2500 ~ "Above 2500",
    TRUE ~ "Unknown"  # This handles any NA or unexpected values
  ))


# Plot
ggplot(data = merged) +
  geom_sf(aes(fill = hhi_firms), color = "white", size = 0.1) +
  theme_minimal()  +  # Start with a minimal theme
  theme(legend.position = c(0.05, 0.95),  # Position the legend inside the top left of the plot
        legend.justification = c(0, 1),  # Anchor point for the legend position
        legend.direction = "vertical",  # Set legend direction to vertical
        panel.grid.major = element_blank(),  # Remove major grid lines
        panel.grid.minor = element_blank(),  # Remove minor grid lines
        axis.text = element_blank(),  # Remove axis text
        axis.ticks = element_blank(),  # Remove axis ticks
        axis.title = element_blank(),  # Remove axis titles
        plot.background = element_blank(),  # Remove plot background
        panel.background = element_blank(),  # Remove panel background
        legend.background = element_rect(fill = "transparent", color = NA),  # Transparent legend background
        legend.box.background = element_blank(),  # Remove legend box background
        legend.key = element_blank()) 

ggplot(data = merged) +
  geom_sf(aes(fill = hhi_firms_category), color = "white", size = 0.1) +
  scale_fill_manual(values = c("Below 1500" = "lightblue", "Between 1500 and 2500" = "blue", "Above 2500" = "darkblue"), name = "HHI Category") +
  theme_minimal() +
  theme(legend.position = c(0.05, 0.95),  # Position the legend inside the top left of the plot
        legend.justification = c(0, 1),  # Anchor point for the legend position
        legend.direction = "vertical",  # Set legend direction to vertical
        panel.grid.major = element_blank(),  # Remove major grid lines
        panel.grid.minor = element_blank(),  # Remove minor grid lines
        axis.text = element_blank(),  # Remove axis text
        axis.ticks = element_blank(),  # Remove axis ticks
        axis.title = element_blank(),  # Remove axis titles
        plot.background = element_blank(),  # Remove plot background
        panel.background = element_blank(),  # Remove panel background
        legend.background = element_rect(fill = "transparent", color = NA),  # Transparent legend background
        legend.box.background = element_blank(),  # Remove legend box background
        legend.key = element_blank())  # Remove legend key background

