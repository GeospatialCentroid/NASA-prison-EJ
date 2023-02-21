# Function to clean filter NASA SEDAC (PEST-CHEMGRIDS) for CalEnviroScreen4.0 Pesticides
# SEDAC dataset: https://sedac.ciesin.columbia.edu/data/set/ferman-v1-pest-chemgrids-v1-01
# CalEnviroScreen list: https://oehha.ca.gov/media/downloads/calenviroscreen/report/calenviroscreen40reportf2021.pdf [Pages 79 - 90]

# File Created: February 15, 2023

library(tidyr)
library(dplyr)
library(tabulizer)


getPesticides <- function(sedac_pesticide_parent){
  # Read in SEDAC ApplicationRate .tif(s)
  sedac_filenames <- list.files(path = paste0(sedac_pesticide_parent,"/ApplicationRate/GEOTIFF"), 
                                pattern = "\\.tif$",
                                full.names = TRUE,
                                no.. = TRUE)
  
  # Create dataframe of SEDAC filenames and associated metadata
  sedac_meta <- data.frame(filename = sedac_filenames, 
                               pest_name = tolower(stringr::word(sedac_filenames, start = 4L, sep = "_")),
                               year = stringr::word(sedac_filenames, start = 5L, sep = "_"))
  
  ## CaliEnviroScreen Pesticides ----
  cal_pest <- extract_tables("data/raw/pesticide_sedac/CalEnviroScreen40_PESTICIDE_LIST.pdf")
  cal_pest_all <- list()
  
  # Clean and stitch together pages of table
  for (i in 1:length(cal_pest)) {
    df_df <- data.frame(cal_pest[i])
    df_cut <- df_df[-(1:3),]
    
    cal_pest_all[[i]] <- df_cut
  }
  
  cal_pest <- cal_pest_all %>% 
    bind_rows(.)
  
  # Clean extra blank spaces, rename variables
  cal_pest_clean <- cal_pest %>% 
    filter(if_all(.cols = everything(), ~ .x != "")) %>% 
    rename_all(., ~c("pesticide_active_ingredient", "use_2017_19_lbs", "enviroscreen_rank"))
  
  # Final list of pesticides from CalEnviroScreen
  cal_pest_list <- tolower(unique(cal_pest_clean$pesticide_active_ingredient))
  
  ## Filter matching pesticides ----
  pesticide_cal_sedac <- sedac_meta[which(grepl(paste0(cal_pest_list, collapse = '|'), sedac_meta$pest_name)),]
  
  pesticide_cal_sedac_filenames <- pesticide_cal_sedac %>% 
    filter(year == 2020)
  
  # Write to processed files
  write.csv(pesticide_cal_sedac_filenames, "data/processed/pesticide_sedac/pesticides_cal_sedac_filenames.csv")
  
  return(pesticide_cal_sedac_filenames)
}

## TEST ----
test_getPesticides <- getPesticides("data/raw/pesticide_sedac/ferman-v1-pest-chemgrids-v1-01-geotiff")
