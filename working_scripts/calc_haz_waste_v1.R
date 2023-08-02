# Using RSEI data 2.3.11 (2021) from the EPA 
# Methods on page 94 of CalEnviroScreen 4.0 Report

# Requesting download of RSEI data (Access granted to AWS storage)

# Initialize Packages, setup ----

library(tidyverse)
library(furrr)
library(feather)

library(mapview)
library(leaflet)

library(terra)
library(sf)


dir.create("data/raw/RSEI_waste")

## From the AWS S3 service:
# 14 = Conterminous US
# 24 = Alaska
# 34 = Hawaii

# Download data from the AWS S3 server ----
getawsRSEI <- function(url_list, directory = "data/raw/RSEI_waste/") {
  # Iterate across each download link, using CURL if file has not been downloaded
  for (url in url_list) {
    
    filename <- stringr::word(url, start = -1, sep = "/")
    filename_dir <- paste0(directory, filename)
    
    if (!file.exists(filename_dir)) {
      message("Downloading: ", filename)
      
      download.file(url, destfile = filename_dir, method = "curl")
    }
    
  }
}

## Download shapefiles ----
region_urls <- c("https://gaftp.epa.gov/rsei/Shapefiles/810m_Standard_Grid_Shapefiles/poly_gc14_conus_810m_bottom",
                 "https://gaftp.epa.gov/rsei/Shapefiles/810m_Standard_Grid_Shapefiles/poly_gc14_conus_810m_top",
                 "https://gaftp.epa.gov/rsei/Shapefiles/810m_Standard_Grid_Shapefiles/poly_gc24_alaska_810m",
                 "https://gaftp.epa.gov/rsei/Shapefiles/810m_Standard_Grid_Shapefiles/poly_gc34_hawaii_810m")
extensions <- c(".dbf", ".prj", ".shp", ".shx")

# Generate map of all (url, shapefile extension)
region_map <- pmap_chr(expand_grid(region_urls, extensions), paste0)


## Waste model data ----
haz_waste_url <- c("http://abt-rsei.s3.amazonaws.com/aggmicro2021/aggmicro2021_")
haz_waste_extensions <- c("_gc14.csv.gz", "_gc24.csv.gz", "_gc34.csv.gz")
haz_waste_years <- c(2019, 2020, 2021)

# Generate map of all (url, region, year)
haz_waste_map <- pmap_chr(expand_grid(haz_waste_url, haz_waste_years, haz_waste_extensions), paste0)


# Download RSEI model data
getRSEI(region_map) # Download grid shapefiles
getRSEI(haz_waste_map) # Download model data for grid


# Computations ----

# Dplyr function to process data from readHazWaste(). Input is a dataframe.
avgWaste <- function(agg_rsei_df){
  
  rsei_calc <- agg_rsei_df %>%
    group_by(cell_code) %>%
    dplyr::summarize(across(.cols = all_of(c("toxic_conc", "score", "score_cancer", "score_non.cancer")),
                            .fns = ~round(mean(.x), 3),
                            .names = "{col}"),
                     num_facilities = round(mean(num_facilities), 0),
                     num_releases = round(mean(num_releases), 0),
                     num_chemicals = round(mean(num_chemicals), 0))
  
  return(rsei_calc)
}

# Workhorse function for extracting, aggregating, and preparing waste data for calculations / export.
# Input is a region code, accessing .csv.gz files downloaded from getRSEI()
readHazWaste <- function(region_code, directory = "data/raw/RSEI_waste/") {
  # browser()
  haz_data_agg <- list() # List to be populated with dataframes
  
  region <- paste0("_gc", region_code, ".csv.gz")
  
  haz_filenames <- list.files(path = "data/raw/RSEI_waste/", 
                              pattern = region,
                              full.names = TRUE)
  
  # Read in each file, add to list
  for (i in 1:length(haz_filenames)) {
    haz_data <- vroom::vroom(haz_filenames[i], col_names = FALSE)
    
    year <- stringr::word(haz_filenames[i], start = 3, end = 3, sep = "_")
    
    haz_data <- haz_data %>% 
      mutate(X11 = year)
    
    haz_data_agg[[i]] <- haz_data
    
  }
  
  message("\nData imported.")
  
  
  # Create full dataframe
  haz_df <- bind_rows(haz_data_agg)
  
  colnames(haz_df) <- c("grid_x", "grid_y", "num_facilities", "num_releases",
                          "num_chemicals", "toxic_conc", "score", "population",
                          "score_cancer", "score_non.cancer", "year")

  
  # Create unique cell_codes using a '*' delimiter, prevents duplicates
  haz_df$cell_code <- as.character(paste0(haz_df$grid_x, '*', haz_df$grid_y))
  
  message("\nRunning calculations...")

  # Call dplyr-style function above
  avg_df <- avgWaste(haz_df)
  
  return(avg_df)
   
}

## Waste data to .feather

# Hazardous waste dataframe
us_rsei <- readHazWaste(14)
feather::write_feather(us_rsei, "data/raw/RSEI_waste/aggmicro2019_2021_gc14.feather")

ak_rsei <- readHazWaste(24)
feather::write_feather(ak_rsei, "data/raw/RSEI_waste/aggmicro2019_2021_gc24.feather")

hi_rsei <- readHazWaste(34)
feather::write_feather(hi_rsei, "data/raw/RSEI_waste/aggmicro2019_2021_gc34.feather")

# ---- Shapefiles ----

# Workhorse function for reading in .shp or .dbf files that contain grid centerpoints.
# Input is region code. (.dbf files preferred to ignore reading in polygon geometry)
readRSEIGrid <- function(region_code = 14, directory = "data/raw/RSEI_waste/"){
  # browser()
  region <- paste0("_gc", region_code)
  
  out_feather <- "data/raw/RSEI_waste/"
  
  haz_filenames <- list.files(path = "data/raw/RSEI_waste/", 
                              pattern = region,
                              full.names = TRUE)
  
  # Read in corresponding .shp and .dbf
  shp_filenames <- stringr::str_subset(haz_filenames, ".shp")
  dbf_filenames <- stringr::str_subset(haz_filenames, ".dbf")
  
  filenames_out <- list() # List of produced .feather files
  
  for (i in 1:length(shp_filenames)) {
    
    message(paste("Reading file:", shp_filenames[i]))
    
    filename <- stringr::word(shp_filenames[i], start = -1, sep = "/") %>% 
      gsub(".shp", "", x = .)
    
    filename_dir <- paste0(out_feather, filename, ".feather") # Output file + dir
    
    filenames_out[i] <- filename_dir # List of outputs
    
    tryCatch(expr = {
      
      if (region_code == 14) { # File for conus has damaged geometries, breaks read.dbf function
        warning("Conus data damaged from source")
      }
      shp_df <- foreign::read.dbf(dbf_filenames[i])
      feather::write_feather(shp_df, filename_dir)
      
      remove(shp_df)
    },
    error = function(e){ 
      message(".dbf error, reading as .shp")
      shp_df <- st_read(shp_filenames[i]) %>% 
        st_drop_geometry(.)
      
      feather::write_feather(shp_df, filename_dir)
      
      remove(shp_df)
    },
    warning = function(w){
      message("Reading data as .shp")
      options(warn = -1)
      
      shp_df <- suppressWarnings(st_read(shp_filenames[i]) %>% 
                                   st_drop_geometry(.))
      
      feather::write_feather(shp_df, filename_dir)
      
      options(warn = 0)
      remove(shp_df)
    },
    finally = {
      message("Trying next site_no...")
    }
    
    )
    
  }
  
  return(filenames_out)
}


# ---- Shapefiles ----
shp_conus <- readRSEIGrid(14)

conus_feather <- stringr::str_subset(feather_filenames, "14")
conus_bot <- feather::read_feather(conus_feather[1])
conus_top <- feather::read_feather(conus_feather[2])

shp_ak <- readRSEIGrid(24)

shp_ak_feather <- feather::read_feather(shp_ak[[1]])

shp_hi <- readRSEIGrid(34)

shp_hi_feather <- feather::read_feather(shp_hi[[1]])

# Read in processed .feather files
feather_filenames <- list.files(path = "data/raw/RSEI_waste/", 
                                pattern = ".feather",
                                full.names = TRUE)

# NEW METHOD ----

# Workflow::
# Buffered Prisons
# Filter if prison is within buffer of cell centerpoint
# Get bounding box of prison (sf)
# get xmin/max ymin/max columns
# Buffer manually (add to max, sub to min for 1km) (dplyr),

## Polygon drop geometery, keeping centerpoint
# calculate using 

# Filter polygon dataset xmin < center X < xmax, ymin < center Y < ymax
# Get vector of grids which are in buffer geom, get values for each year using nesting


prisons <- read_sf('data/processed/study_prisons.shp')

prisons_conus <- prisons_unique %>% filter(!(STATE %in% c("AK", "HI"))) %>% 
  st_crs(., shp_conus)
prisons_ak <- prisons_unique %>% filter(STATE == "AK") %>% 
  st_crs(., shp_ak)
prisons_hi <- prisons_unique %>% filter(STATE == "HI") %>% 
  st_crs(., shp_hi)

prisons_buff <- prisons %>% 
  st_buffer(1000)


  

