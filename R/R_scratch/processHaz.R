#process hazardous waste

library(tidyverse)
library(XML)
library(xml2)
library(vroom)


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
  programName = programName,
  interestType = interestType
) # error because more program name and interest type than



# try reading in csv of all FRS sites

all_frs <- vroom("data/raw/national_single_EPA_FRS/NATIONAL_SINGLE.CSV")



# filter out TSDs and LQGs

haz_sites <- all_frs %>% 
  filter(str_detect(INTEREST_TYPES, "LQG|TSD"))
  


# compare with TRI data
tri <- read_csv("data/raw/2021_us_toxic_release_inventory.csv")

#only 5k haz sites in tri


# look at tdsf data downloaded from EPA
tsdf <- read_csv("data/raw/hazardous_waste/rcaInfo_TSDF.csv")
