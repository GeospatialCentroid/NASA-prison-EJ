#' Get count of power plants within buffer zones
#'
#' A function to clean Global Power Plant dataset from the World Resources Institute (WRI)
#' and get a count of how many toxin releasing plants are within buffers of prisons with `calcPrisonProximity()`.
#'
#' @param prisons An sf object of all prison polygons to be assessed
#' @param filePath the file path pointing to global power plant dataset
#' @param dist The buffer distance(s) (in meters) to add around prison boundaries
#' @param save Whether to save (TRUE) the resulting dataframe (as .csv) or not (FALSE)
#' @param writePath If `save = TRUE`, the file path to the folder to save the output csv to.
#' @source calcPrisonProximity() for getting counts within buffers
#' 
#' @return A tibble with total area and percent area flood risk zones cover the buffered prison boundary
getPowerPlants <- function(prisons, filePath = "data/raw/power_plants/global_power_plant_database_v_1_3/global_power_plant_database.csv", 
                            dist = c(1000, 5000, 10000, 20000, 40000), save = TRUE, writePath = 'data/processed/'){
  
  source("R/src/calcPrisonProximity.R")
  
  # Importing data
  global_power <- read_csv(filePath)
  
  # Filter for non-renewable United States plants
  us_power <- global_power %>% 
    filter(country == "USA",
           !primary_fuel %in% c("Solar", "Wind", "Hydro")) %>% 
    mutate(commissioning_year = as.integer(commissioning_year))
  
  # Make spatial feature
  us_power_sf <- us_power %>%
    st_as_sf(coords = c("longitude", "latitude"), crs = 4326)
  
  prisons_sub <- prisons %>% 
    select(., FACILITYID)
  
  prisons_power <- calcPrisonProximity(prisons_sub, us_power_sf, 'power', dist)
  
  prisons_power <- prisons_power %>% 
    select(1:2, all_of(ends_with("count"))) %>% 
    st_drop_geometry(.)
  
  if (save == TRUE) { 
    
    write_csv(prisons_power, paste0(writePath, "prisons_powerplant.csv"))
    }
}

