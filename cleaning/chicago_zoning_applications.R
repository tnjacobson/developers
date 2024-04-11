#Extracting Data from Zoning Applications


#Setting Paths
source(file.path(Sys.getenv("HOME"),"Documents/Github/developers","prelim.R"))
library(data.table)
library(stringr)

#Loading Data
data <- fread(file.path(d_data,"raw/councilmatic", "zoning2023.csv"))


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
mean(data_new$clean_address)



#-------------------------------------------------------------------------------
#Extracting Info From Reports
#-------------------------------------------------------------------------------
# Extract Applicant
data_new$application_text <- str_extract(data_new$extras, "(?<=APPLICATION FOR AN AMENDMENT TO THE CHICAGO ZONING ORDINANCE)(.*?)(?=NOTARY PUBLIC)")

data_new <- data_new %>% filter(!is.na(application_text))



#Getting Applicant Name
data_new$applicant <- str_extract(data_new$application_text, "(?<=APPLICANT\\s)([^\\\\]+)")


pattern <- "APPLICANT(.*?)(?=Is the applicant )"
data_new$applicant_info <- str_extract(data_new$application_text, pattern)



# Extract Address
address_pattern <- "ADDRESS(.*?)(?=STATE)"
data_new$applicant_address <- str_extract(data_new$applicant_info, address_pattern)

# Extract ZIP Code
zip_pattern <- "ZIP(.*?)(?=PHONE)"
data_new$applicant_zip <- str_extract(data_new$applicant_info, zip_pattern)

# Extract Phone Number
phone_pattern <- "PHONE(.*?)(?=EMAIL)"
data_new$applicant_phone <- str_extract(data_new$applicant_info, phone_pattern)

# Extract Email
email_pattern <- "EMAIL(.*?)(?=CONTACT)"
data_new$applicant_email <- str_extract(data_new$applicant_info, email_pattern)

# Extract Contact Person
contact_person_pattern <- "PERSON(.*?)(?=\\t|\\n)"
data_new$contact_person <- str_extract(data_new$applicant_info, contact_person_pattern)

# Extract Reason
reason_pattern <- "Reason(.*?)(?=Describe)"
data_new$reason<- str_extract(data_new$application_text, reason_pattern)


