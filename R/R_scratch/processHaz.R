#process hazardous waste

library(tidyverse)
library(XML)
library(xml2)
library(vroom)


# import EPA FRS (facility register service) .xml that includes TSDFs and LQGs
# Last updated March 2023: https://www.epa.gov/frs/geospatial-data-download-service

# this doesn't work, try to use xml2 and tidyverse approach instead https://urbandatapalette.com/post/2021-03-xml-dataframe-r/
#epa_frs <- xmlToDataFrame("data/raw/EPA_FRS-facilities/EPAXMLDownload.xml")

#transform xml to list
xml_list <- as_list(read_xml("data/raw/EPA_FRS-facilities/EPAXMLDownload.xml"))


#expand the data to multiple rows by tags

xml_df <- as_tibble(xml_list) %>% 
  unnest_longer(DATA)










# try reading in csv of all FRS sites

all_frs <- vroom("data/raw/national_single_EPA_FRS/NATIONAL_SINGLE.CSV")



# filter out TSDs and LQGs

haz_sites <- all_frs %>% 
  filter(str_detect(INTEREST_TYPES, "LQG|TSD"))
  
