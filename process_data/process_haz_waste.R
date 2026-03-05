# code to import raw EPA FRS file and filter desired hazardous waste sites
## Choice for hazardous waste sites follows methods of EPA EJ Screen: TSDFs and LQGs

library(tidyverse)
library(vroom)


# csv of all FRS sites

all_frs <- vroom("data/phase2/raw/FRS/NATIONAL_SINGLE.CSV")


# filter for TSDs and LQGs and save cleaned data set to 'processed/' folder

all_frs %>% 
  filter(str_detect(INTEREST_TYPES, "LQG|TSD")) %>% 
  filter(!is.na(LONGITUDE83) | !is.na(LATITUDE83)) %>%  # ~1600 missing coordinates due to vague address description
  write_csv("data/phase2/processed/hazardous_waste/TSD_LQGs.csv")
