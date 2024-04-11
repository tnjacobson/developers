#Geocode and Clean Agendas


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


#Load in Agendas
agendas = fread(file.path(d_data,"intermediate", "proposals_ocr.csv"))

#-------------------------------------------------------------------------------
#Extract Zoning Codes
#-------------------------------------------------------------------------------


#Load in Qualities
class_qualities <- fread(file.path(d_data,"raw/secondcityzoning", "zoning-code-summary-district-types.csv"))%>%
  mutate(log_floor_area_ratio = log(as.numeric(floor_area_ratio)))
zoning_codes = gsub("-", "", class_qualities$district_type_code)
zoning_codes = head(zoning_codes, -1)

#Write Function to Extract Zoning Codes
extract_zoning_codes <- function(description, codes) {
  # Replace each code with a version that allows optional dashes
  modified_codes <- sapply(codes, function(code) gsub("(.)", "\\1\\-?", code))
  
  # Create a pattern that matches any of the modified codes
  pattern <- paste(modified_codes, collapse = "|")
  
  # Extract matches
  matches <- regmatches(description, gregexpr(pattern, description))
  
  # Return unique matches
  return(unique(unlist(matches)))
}

#Splitting the Description Before and After the First "To"
agendas$before_to <- sapply(strsplit(agendas$Description, "(?i)\\s+to\\s+", perl = TRUE), function(x) trimws(x[1]))
agendas$after_to <- sapply(strsplit(agendas$Description, "(?i)\\s+to\\s+", perl = TRUE), function(x) {
  if (length(x) > 1) trimws(x[2]) else NA
})


# Define the columns to process
columns_to_process <- c("before_to", "after_to")

# Loop through the columns
for (col in columns_to_process) {

  # Removing Dashes
  agendas[[col]] <- gsub("-", "", agendas[[col]])
  
  # Extract Codes
  agendas[[paste0("codes_", col)]] <- sapply(agendas[[col]], extract_zoning_codes, codes = zoning_codes)
  
  # Look for PD
  pattern <- "(?i)\\b(Planned Development|PD)\\b"
  agendas[[paste0("pd_", col)]] <- grepl(pattern, agendas[[col]], perl = TRUE)
  
  # Find the largest length among the character vectors
  largest_length <- max(sapply(agendas[[paste0("codes_", col)]], length))
  
  # Create new variables codes_before_1 through codes_before_6
  for (i in 1:largest_length) {
    # Create a new variable with the name "codes_before_i"
    new_variable_name <- paste0("codes_", col, "_", i)
    
    # Use sapply to extract the i-th element from each character vector
    agendas[[new_variable_name]] <- sapply(agendas[[paste0("codes_", col)]], function(vec) {
      if (length(vec) >= i) {
        return(vec[i])
      } else {
        return(NA_character_)
      }
    })
  }
  
  # Replace with PD in the first code column
  agendas[[paste0("codes_", col, "_1")]][is.na(agendas[[paste0("codes_", col, "_1")]]) & agendas[[paste0("pd_", col)]]] <- "PD"
}

# Calculate the coverage rate for codes_before_1
coverage_before_1 <- sum(!is.na(agendas$codes_before_to_1)) / nrow(agendas)

# Calculate the coverage rate for codes_after_1
coverage_after_1 <- sum(!is.na(agendas$codes_after_to_1)) / nrow(agendas)

# Print the coverage rates
cat("Coverage rate for codes_before_1:", coverage_before_1 * 100, "%\n")
cat("Coverage rate for codes_after_1:", coverage_after_1 * 100, "%\n")

#Looking Through Problems
filtered_before_agendas <- agendas[is.na(agendas$codes_before_to_1),]
#Try Changing 8 to B
filtered_before_agendas$before_to = gsub("8","B",filtered_before_agendas$before_to )
# Assuming 'filtered_before_agendas' is your data frame, and 'zoning_codes' is defined

# Loop through the columns
for (col in columns_to_process) {
  # Removing Dashes
  filtered_before_agendas[[col]] <- gsub("-", "", filtered_before_agendas[[col]])
  
  # Extract Codes
  filtered_before_agendas[[paste0("codes_", col)]] <- sapply(filtered_before_agendas[[col]], extract_zoning_codes, codes = zoning_codes)
  
  # Look for PD
  pattern <- "(?i)\\b(Planned Development|PD)\\b"
  filtered_before_agendas[[paste0("pd_", col)]] <- grepl(pattern, filtered_before_agendas[[col]], perl = TRUE)
  
  # Find the largest length among the character vectors
  largest_length <- max(sapply(filtered_before_agendas[[paste0("codes_", col)]], length))
  
  # Create new variables codes_before_1 through codes_before_6
  for (i in 1:largest_length) {
    # Create a new variable with the name "codes_before_i"
    new_variable_name <- paste0("codes_", col, "_", i)
    
    # Use sapply to extract the i-th element from each character vector
    filtered_before_agendas[[new_variable_name]] <- sapply(filtered_before_agendas[[paste0("codes_", col)]], function(vec) {
      if (length(vec) >= i) {
        return(vec[i])
      } else {
        return(NA_character_)
      }
    })
  }
  
  # Replace with PD in the first code column
  filtered_before_agendas[[paste0("codes_", col, "_1")]][is.na(filtered_before_agendas[[paste0("codes_", col, "_1")]]) & filtered_before_agendas[[paste0("pd_", col)]]] <- "PD"
}
#-------------------------------------------------------------------------------
#Agenda Dates
#-------------------------------------------------------------------------------
#Load in Events
event <- fread(file.path(d_data,"raw/councilmatic/agendas", "event.csv"))%>%
  filter(name == "Committee on Zoning, Landmarks and Building Standards")
eventdoc <- fread(file.path(d_data,"raw/councilmatic/agendas", "eventdocument.csv"))
eventdoclink <- fread(file.path(d_data,"raw/councilmatic/agendas", "eventdocumentlink.csv"))

merged_data <- merge(event, eventdoc, by.x = "id", by.y = "event_id")%>%
  rename( doc_id = id.y)%>%
  filter(note == "Agenda")

documents =  merge(merged_data, eventdoclink, by.x = "doc_id", by.y = "document_id")

documents_short = documents %>%
    select(url, start_date)%>%
  mutate(date = sub(" .*", "", start_date))

agendas = left_join(agendas,documents_short, by = "url")




#-------------------------------------------------------------------------------
#Adding Qualities Before and After
#-------------------------------------------------------------------------------

#Merge on Qualities
class_qualities_short = class_qualities %>%
  mutate(district_type_code = gsub("-","",district_type_code))%>%
  select(district_type_code,district_title, floor_area_ratio, lot_area_per_unit, maximum_building_height)

# Perform the left join using codes_before_to_1 and district_type_code, and suffix _before
merged_df_before <- left_join(agendas, class_qualities_short, by = c("codes_before_to_1" = "district_type_code"))%>%
  rename(
    district_title_before = district_title,
    floor_area_ratio_before = floor_area_ratio,
    lot_area_per_unit_before = lot_area_per_unit,
    maximum_building_height_before = maximum_building_height
  )%>%
  select(-codes_before_to, -codes_after_to)

merged_df <- left_join(merged_df_before, class_qualities_short, by = c("codes_after_to_1" = "district_type_code"))%>%
  rename(
    district_title_after = district_title,
    floor_area_ratio_after = floor_area_ratio,
    lot_area_per_unit_after = lot_area_per_unit,
    maximum_building_height_after = maximum_building_height
  )

#Save for Stata
merged_df_short = merged_df%>%
    select(-Description, -after_to, -before_to)
write.csv(merged_df_short, file = file.path(d_data,"intermediate", "agendas_clean.csv"),row.names = FALSE)

write.table(data, "output_file.txt", sep = "|", quote = FALSE, row.names = FALSE)

#-------------------------------------------------------------------------------
#Geocoding
#-------------------------------------------------------------------------------
# Create a function to split and clean the addresses
data = fread( file = file.path(d_data,"intermediate", "agendas_clean.csv"))
addresses 
clean_addresses <- function(addresses) {
  # Split multiple addresses by semicolon
  split_addresses <- strsplit(addresses, "; ")
  
  # Initialize empty lists for cleaned addresses
  cleaned_addresses <- list()
  
  # Loop through each set of addresses
  for (addr_set in split_addresses) {
    cleaned_addr_set <- c()
    
    # Loop through individual addresses in the set
    for (addr in addr_set) {
      
      #First Split by cardinal direction to get first number
      numbers<- gsub("^(.*?)[NSWE].*", "\\1", addr)
      
      #Storing Everything Else
      after_numbers = gsub(numbers, "", addr)
      
      #Getting First Number
      numbers<- gsub("and", ",", numbers)
      numbers<- gsub("-", ",", numbers)
      first_number = str_extract(numbers, "\\d+")
      first_address = paste(first_number, after_numbers)

      # Append the ranges to the cleaned address set
      cleaned_addr_set <- c(cleaned_addr_set, first_address)
    }
    
    # Append the cleaned address set to the list
    cleaned_addresses[[length(cleaned_addresses) + 1]] <- cleaned_addr_set
  }
  
  # Convert the list of cleaned addresses to a data frame
  cleaned_df <- as.data.frame(do.call(rbind, lapply(cleaned_addresses, `length<-`, max(lengths(cleaned_addresses)))))
  
  # Add column names
  colnames(cleaned_df) <- paste0("Address_", 1:ncol(cleaned_df))
  
  return(cleaned_df)
}

# Clean the addresses and store in a data frame
test <- clean_addresses(test_addresses)


# Regular expression pattern to match the desired format
pattern <- "^[0-9]{3,4} [NWSE] [A-Za-z ]+$"

# Create a new column "IsCleanAddress" based on the pattern match
test <- test %>%
  mutate(IsCleanAddress = grepl(pattern, Address_1))
mean(test$IsCleanAddress)


test_addresses=head(data,n=100)$Common_Address
addresses = test_addresses


merged_df = merged_df%>%
   
  agendas %>%
  separate(Common_Address, sep = " and ", fill = "right")

agendas_tail=tail(agendas,n=100)%>%
  mutate(address = paste0(Common_Address, ", Chicago, IL"))



geocoded_df <- agendas_tail %>%
  geocode(address, method = 'google')
geocoded_df_census <- agendas_tail %>%
  geocode(address, method = 'census')



# Drop rows with missing coordinates
geocoded_df <- geocoded_df[complete.cases(geocoded_df[c("lat", "long")]), ]

# Convert the cleaned geocoded data frame into a spatial data frame
spatial_df <- st_as_sf(geocoded_df, coords = c("long", "lat"), crs = 4326)

#-------------------------------------------------------------------------------
#Merge with Zoning Map
#-------------------------------------------------------------------------------
#Load in Current Zoning Map
zoningcurrent <- st_read(file.path(d_data,"raw/Boundaries - Zoning Districts (current)", "current_zoning.shp"))
zoningcurrent =st_transform(zoningcurrent, crs = 4326)
zoningcurrent = st_make_valid(zoningcurrent)
#Load in Past Zoning Map
zoning2012 <- st_read(file.path(d_data,"raw/Zoning 2012", "Zoning_nov2012.shp"))
zoning2012 =st_transform(zoning2012, crs = 4326)
zoning2012 = st_make_valid(zoning2012)

joined_df <- sf::st_join(spatial_df, zoningcurrent, join = st_within)
joined_df <- sf::st_join(joined_df, zoning2012, join = st_within)

#Checking how the new codes are
joined_df$zone_class = gsub("-","",joined_df$zone_class)
joined_df$ZONE_CLASS = gsub("-","",joined_df$ZONE_CLASS)


joined_df=joined_df%>%
  mutate(match = zone_class == codes_after_to_1)

view(joined_df[,c("zone_class", "ZONE_CLASS", "codes_after_to_1", "codes_before_to_1", "Description")])
