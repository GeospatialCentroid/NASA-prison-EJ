#process hazardous waste

library(tidyverse)
library(XML)
library(xml2)
library(vroom)
library(sf)


# import EPA FRS (facility register service) .xml that includes TSDFs and LQGs
# Last updated March 2023: https://www.epa.gov/frs/geospatial-data-download-service

# this doesn't work, try to use xml2 and tidyverse approach instead https://urbandatapalette.com/post/2021-03-xml-dataframe-r/
epa_frs <- xmlToDataFrame("data/raw/EPA_FRS-facilities/EPAXMLDownload.xml")


test <- xmlToDataFrame(nodes = xmlChildren(xmlRoot(frs_parse)[["FacilitySite"]]))


#transform xml to list (takes really long...)
xml_list <- as_list(read_xml("data/raw/EPA_FRS-facilities/EPAXMLDownload.xml"))


#expand the data to multiple rows by tags

xml_df <- as_tibble(xml_list) %>% 
  unnest_longer(DATA)


## most promising workflow here -------------------------------------------------
# inspect xml first
frs_data <- read_xml("data/raw/EPA_FRS-facilities/EPAXMLDownload.xml")

# parse
frs_parse <- xmlParse("data/raw/EPA_FRS-facilities/EPAXMLDownload.xml")

# find all nodes?
facility <- xml_text(xml_find_all(frs_data, "//FacilitySiteName"))

xml_structure(frs_data)


# create data frame

## get registry ID (unique because it is an attribute of a child note)
registryID <- xml_attr(xml_children(frs_data), "registryId")[-1] #remove first value because NA

facilitySiteName <- xml_text(xml_find_all(frs_data, "//FacilitySiteName"))
state <- xml_text(xml_find_all(frs_data, "//LocationAddressStateCode"))
lat <- xml_double(xml_find_all(frs_data, "//LatitudeMeasure"))
long <- xml_double(xml_find_all(frs_data, "//LongitudeMeasure"))
crs <- xml_text(xml_find_all(frs_data, "//HorizontalCoordinateReferenceSystemDatumName"))
programName <-  xml_text(xml_find_all(xml_children(frs_data), "//ProgramCommonName"))
interestType <- xml_text(xml_find_all(frs_data, "//ProgramInterestType"))


frs_df <- tibble(
  registryID = registryID,
  facilitySiteName = facilitySiteName,
  state = state,
  lat = lat,
  long = long,
  crs = crs,
  # programName = programName,
  # interestType = interestType
) # error because multiple program name and interest type per facility..



# csv of all FRS sites -------------------------------------------------

all_frs <- vroom("data/raw/national_single_EPA_FRS/NATIONAL_SINGLE.CSV")



# filter out TSDs and LQGs

haz_sites <- all_frs %>% 
  filter(str_detect(INTEREST_TYPES, "LQG|TSD"))
  

# save this file, inspect later and may use as final dataset
write_csv(haz_sites, "data/raw/hazardous_waste/TSD_LQGs_raw.csv")


## inspect this, does it seem like it captures all the haz sites?
haz_sites <- read_csv("data/raw/hazardous_waste/TSD_LQGs_raw.csv")


# see how many of these are within the FRS xml above
haz_sites %>% filter(REGISTRY_ID %in% frs_df$registryID)
# 39840, so almost all of them. Inspect the interest types for the ~2k missing

haz_sites %>% filter(!REGISTRY_ID %in% frs_df$registryID) %>% pull(INTEREST_TYPES) %>% 
  unique()
# all still LQGs or TSDs, so let's use this data for the indicator calculation


# TRI data ---------------------------------------------------------------
tri <- read_csv("data/raw/2021_us_toxic_release_inventory.csv")

#only 5k haz sites in tri


# tdsf data downloaded from EPA ------------------------------------------
tsdf <- read_csv("data/raw/hazardous_waste/rcaInfo_TSDF.csv")



# kmz data download (converted to shapefile in pro) --------------------
frs_kmz <- read_sf("data/raw/hazardous_waste/EPA_FRS_kmz_export.shp")
