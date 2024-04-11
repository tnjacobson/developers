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

# Load the CSV file as a data frame
intersection_current <- read.csv(file.path(d_data,"intermediate", "intersection_current.csv"))
