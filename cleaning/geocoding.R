#Extracting Data from Zoning Applications


#Setting Paths
source(file.path(Sys.getenv("HOME"),"Documents/Github/developers","prelim.R"))
library(data.table)
library(stringr)
library(httr)
library(jsonlite)
library(tidygeocoder)



api_key = "aea740b7c20549bf9a7341a0bea21cb9"

#-------------------------------------------------------------------------------
#Basic Address Cleaning
#-------------------------------------------------------------------------------


final_data <- data.frame()


years <- 2010:2023  # for instance, from 2001 to 2020

for (year in years) {
  
  data <- fread(file.path(d_data,"raw/councilmatic", paste0("zoning",year,".csv")))
  
  
  #Extracting Address from Title
  data[, address_raw := sub(".* at ?(.*?)( ?- App No. .*|$)", "\\1", title)]
  
  #Removing Spaces
  data[, address_raw := trimws(address_raw)]
  
  
  # Split and pad/trim to ensure consistent length of 3
  split_and_pad_trim <- function(address) {
    split_addresses <- unlist(strsplit(address, " and |/|,"))
    
    # If there are more than 3 addresses, keep only the first 3
    if (length(split_addresses) > 3) {
      split_addresses <- split_addresses[1:3]
    }
    # If there are fewer than 3 addresses, pad with NA
    else {
      length(split_addresses) <- 3
    }
    
    return(split_addresses)
  }
  
  addresses <- data[, as.list(split_and_pad_trim(address_raw)), by = id]
  
  # Rename the columns
  setnames(addresses, old = names(addresses)[-1], new = c("address_1", "address_2", "address_3"))
  
  # Merge with the original data if necessary
  data_new <- cbind(data, addresses[, -1, with = FALSE])
  
  #Check if Address is Clean
  data_new[, clean_address := ifelse(grepl("^\\d+(-\\d+)? [NSEW] \\w+( \\w+)*$", address_1, ignore.case = TRUE), 1, 0)]
  print(mean(data_new$clean_address))
  
  data_short = data_new[,.(title, legislative_session_id_label, address_1,address_2, address_3, clean_address)]
  data_short[,year := year]
  
  #Append
  final_data <- rbind(final_data, data_short)
}


write_csv(final_data, file.path(d_data,"derived/councilmatic", "zoning_applications.csv"))

#-------------------------------------------------------------------------------
#Geocoding
#-------------------------------------------------------------------------------
test_data = head(final_data, n=100)%>%
  filter(clean_address == 1)%>%
  mutate(address = paste0(address_1, ", Chicago, IL"))


geocoded_df <- test_data %>%
  geocode(address, method = 'census')


geocoded_df=geocoded_df %>%
  mutate(has_geo = ifelse(!is.na(lat), 1, 0))
mean(geocoded_df$has_geo)

test_data = head(final_data, n=100)%>%
  filter(clean_address == 1)%>%
  mutate(address = paste0(address_1, ", Chicago, IL"))

