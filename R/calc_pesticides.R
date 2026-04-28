#' Calculate pesticide application quantities using PEST-CHEMGRIDSv2.01
#' 
#' 
#' source: https://figshare.com/articles/dataset/PESTCHEMGRIDS_v2_01_beta_version_/25854769 
#'
#' This function uses application rates from PEST-CHEMGRIDSv2.01 NetCDF rasters
#' and calculates the mean total pesticide application rate within a buffer around
#' each prison facility. Mirrors the logic of the v1 SEDAC-based function.
#'
#' @param sf_obj       An sf object of prison polygons; must have a FACILITYID column
#' @param folder       File path to the folder containing all PEST-CHEMGRIDSv2.01 .nc files,
#'                     including Countries_2018.nc
#' @param year         Year to extract: 2015 or 2018 (default: 2018)
#' @param dist         Buffer distance in meters around prison boundaries (default: 1000)
#' @param save         Whether to save the output as a .csv (default: TRUE)
#' @param out_path     Folder path for saving output csv (default: "outputs/")
#'
#' @return A data frame with columns: FACILITYID, pesticide_mean_kg

calc_pesticides <- function(sf_obj,
                               folder,
                               year = 2018,
                               dist = 0, # keep at 0 since this raster is 5km
                               save = TRUE,
                               out_path = "outputs/") {
  
  if (!year %in% c(2015, 2018)) stop("`year` must be 2015 or 2018 for PEST-CHEMGRIDSv2.01")
  
  # --- 1. Load US mask -------------------------------------------------------
  us_mask <- terra::ifel(terra::rast(file.path(folder, "Countries_2018.nc")) == 208, 1, NA)
  
  # --- 2. List all pesticide .nc files (exclude country mask) ----------------
  pest_files <- list.files(folder, pattern = "\\.nc$", full.names = TRUE)
  pest_files <- pest_files[!grepl("Countries_2018", pest_files)]
  if (length(pest_files) == 0) stop("No .nc files found in `folder`. Check the path.")
  message(sprintf("Found %d pesticide files. Processing year %d...", length(pest_files), year))
  
  layer_H <- paste0("apr_H_year=", year)
  layer_L <- paste0("apr_L_year=", year)
  
  ### GENERATE pesticide mean files, create SUM spatRaster -------------------
  rast_mean <- list()
  
  pb <- progress::progress_bar$new(
    format = "  [:bar] :current/:total | :percent | ETA: :eta",
    total = length(pest_files),
    clear = FALSE,
    width = 70
  )
  
  # Iterate over each compound x crop file, mask to US, then calculate mean of H/L
  for (i in seq_along(pest_files)) {
    
    r <- terra::rast(pest_files[[i]])
    terra::crs(r) <- "EPSG:4326" # set CRS from metadata
    
    rast_H <- terra::mask(r[[layer_H]], us_mask)
    rast_L <- terra::mask(r[[layer_L]], us_mask)
    
    # Replace negative values with zero
    rast_H[rast_H < 0] <- 0
    rast_L[rast_L < 0] <- 0
    
    # Calculate mean of H/L for this compound x crop
    rast_mean[[i]] <- mean(rast_H, rast_L)
    
    pb$tick()
  }
  
  # Stack and sum application rates across all compound x crop combinations
  total_sum <- sum(terra::rast(rast_mean), na.rm = TRUE)

  ## Extract total application rate averaged within each prison buffer --------
  
  # Check CRS match, transform prisons if needed
  if (terra::crs(sf_obj) != terra::crs(total_sum)) {
    sf_obj <- sf::st_transform(sf_obj, crs = terra::crs(total_sum))
  }
  
  prisons_pest <- sf_obj %>%
    sf::st_buffer(dist = dist) %>%
    mutate(pesticide_mean_kg = exactextractr::exact_extract(total_sum, ., fun = "weighted_mean", weights = "area")) %>%
    sf::st_drop_geometry() %>%
    dplyr::select(FACILITYID, pesticide_mean_kg)
  
  if (save) {
    readr::write_csv(prisons_pest, paste0(out_path, "/pesticides", "_", Sys.Date(), ".csv"))
  }
  
  return(prisons_pest)
  
}