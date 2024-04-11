#Downloading Agendas


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
#-------------------------------------------------------------------------------
#Get a list of URLs for Meetings ID
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

url_list = documents$url
date_list = documents$start_date


#-------------------------------------------------------------------------------
#PDF Extraction Function
#-------------------------------------------------------------------------------

# Function to extract fields from a record
extract_fields <- function(record) {
  list(
    NO = str_extract(record, "A-\\d+"),
    WARD = str_extract(record, "\\(.*? WARD\\)"),
    ORDINANCE_REFERRED_DATE = str_extract(record, "\\(\\d{1,2}-\\d{1,2}-\\d{2,4}\\)"),
    DOCUMENT = str_extract(record, "DOCUMENT #[0-9-]+"),
    Common_Address = str_match(record, "Common Address: ([^\\n]+)")[2],
    Applicant = str_match(record, "Applicant: ([^\\n]+)")[2],
    Owner = str_match(record, "Owner: ([^\\n]+)")[2],
    Attorney = str_match(record, "Attorney: ([^\\n]+)")[2],
    Description = str_match(record, "(?s)Change Request: (.*)")[2]
  )
}


#-------------------------------------------------------------------------------
#Process PDFs
#-------------------------------------------------------------------------------
# Initialize an empty list to store data
all_data <- list()
error_data<-list()

#Loop through the PDFs 
for (url in url_list) {
  
  # Download and read the PDF
  #download.file(url, destfile = "document.pdf", mode = "wb")
 # text <- pdf_text("document.pdf")
  
  #text <- paste(text, collapse = " ")

  # Split the text into records
  #records <- str_split(text, "NO\\. ")[[1]][-1]
  #Check if Records is Empty
  #if (length(records) == 0) {
    cat("No records found. Trying OCR")
    image <- image_read_pdf(url)
    image <- image_convert(image, type = 'Grayscale') %>% 
      image_resize('2000x')  # Resize for better accuracy
    text <- ocr(image)
    text <- paste(text, collapse = " ")
    
    records <- str_split(text, "NO\\. ")[[1]][-1]
    if (length(records) == 0) {
      cat("No records found in OCR. Break")
      error_data[[i]] = url
      next
    }
    
  #}
    
  # Apply the function to each record
  data <- bind_rows(lapply(records, extract_fields))
  
  #Add URL
  data$url = url
  
  # Use regular expression to extract the date after "STANDARDS"
  data$meeting_date = date_list[i]
  
  #Check Coverageß
  coverage_result <-check_coverage(data)
  print(mean(coverage_result$Coverage))
  #if (mean(coverage_result$Coverage) < 50) {
    #print(paste0("Broke on URL:", i))
    #error_data[[url]] <- data
    #break 
    #}
    
  
  # Convert the list to a data frame
  all_data[[url]] <- data
  
  i = i +1
}

# Combine all data frames into a single data frame
error_df <- do.call(rbind, error_data)

final_df <- do.call(rbind, all_data)
coverage_result <- check_coverage(final_df)

write.csv(final_df, file = file.path(d_data,"intermediate", "proposals_ocr.csv"), row.names = FALSE)



#-------------------------------------------------------------------------------
#testing
#-------------------------------------------------------------------------------

records <- str_split(text, "NO\\. ")[[1]][-1]
Purpose = str_match(record, "(?s)Purpose: (.*)")[2]
result <- str_match(record, "Change Request: ([^P]+)Purpose:")

Change_Request =str_match(record, "(?s)Change Request: (.*)")[2]
record <- "Change Request: C1-1 Neighborhood Commercial District and C1-2 Neighborhood Commercial\nDistrict to a DX-5 Downtown Mixed Use District and then to a Business Planned Development\nPurpose: This is the purpose statement.\nChange Request: Another change request\nPurpose: Another purpose statement."

