#' Calculate pesticide application quantities using PEST-CHEMGRIDSv2.01
#' 
#' source: https://figshare.com/articles/dataset/PESTCHEMGRIDS_v2_01_beta_version_/25854769 
#'
#' This function uses application rates from PEST-CHEMGRIDSv2.01 NetCDF rasters
#' and calculates the mean total pesticide application rate within a buffer around
#' each facility. Mirrors the logic of the v1 SEDAC-based function.
#'
#' @param sf_obj    An sf object of facility polygons; must have an id_column column
#' @param folder    File path to the folder containing all PEST-CHEMGRIDSv2.01 .nc files,
#'                  including Countries_2018.nc
#' @param year      Year to extract: 2015 or 2018 (default: 2018)
#' @param dist      Buffer distance in meters around facility boundaries (default: 0,
#'                  kept at 0 since this raster is ~5km resolution)
#' @param id_column A string specifying the name of the unique facility identifier column
#'                  (e.g., "FACILITYID" for prisons, "object_id" for ICE detention facilities).
#'                  Default is "FACILITYID".
#' @param save      Whether to save the output as a .csv (default: TRUE)
#' @param out_path  Folder path for saving output csv (default: "outputs/")
#'
#' @return A data frame with columns: {id_column}, pesticide_mean_kg

calc_pesticides <- function(sf_obj,
                            folder,
                            year = 2018,
                            dist = 0,
                            id_column = "FACILITYID",
                            save = TRUE,
                            out_path = "outputs/") {
  
  if (!year %in% c(2015, 2018)) stop("`year` must be 2015 or 2018 for PEST-CHEMGRIDSv2.01")
  
  # --- 1. Load US mask -------------------------------------------------------
  us_mask <- terra::ifel(terra::rast(file.path(folder, "Countries_2018.nc")) == 208, 1, NA)
  terra::crs(us_mask) <- "EPSG:4326"
  
  # --- 2. List all pesticide .nc files (exclude country mask) ----------------
  pest_files <- list.files(folder, pattern = "\\.nc$", full.names = TRUE)
  pest_files <- pest_files[!grepl("Countries_2018", pest_files)]
  if (length(pest_files) == 0) stop("No .nc files found in `folder`. Check the path.")
  message(sprintf("Found %d pesticide files. Processing year %d...", length(pest_files), year))
  
  layer_H <- paste0("apr_H_year=", year)
  layer_L <- paste0("apr_L_year=", year)
  
  # --- 3. Write per-compound mean rasters to temp files -----------------------
  tmp_dir <- file.path(tempdir(), "pesticide_tmp")
  dir.create(tmp_dir, showWarnings = FALSE)
  
  pb <- progress::progress_bar$new(
    format = "  [:bar] :current/:total | :percent | ETA: :eta",
    total = length(pest_files),
    clear = FALSE,
    width = 70
  )
  
  tmp_files <- vector("character", length(pest_files))
  
  for (i in seq_along(pest_files)) {
    
    r <- terra::rast(pest_files[[i]])
    terra::crs(r) <- "EPSG:4326"
    
    rast_H <- terra::mask(r[[layer_H]], us_mask)
    rast_L <- terra::mask(r[[layer_L]], us_mask)
    
    rast_H[rast_H < 0] <- 0
    rast_L[rast_L < 0] <- 0
    
    rast_mean_i <- mean(rast_H, rast_L)
    
    tmp_files[i] <- file.path(tmp_dir, paste0("pest_", i, ".tif"))
    terra::writeRaster(rast_mean_i, tmp_files[i], overwrite = TRUE)
    
    rm(r, rast_H, rast_L, rast_mean_i)
    
    pb$tick()
  }
  
  # --- 4. Stack from disk and sum with na.rm = TRUE ---------------------------
  message("Summing across compounds...")
  total_sum <- terra::rast(tmp_files) %>% 
    terra::app(fun = "sum", na.rm = TRUE)
  
  # clean up temp files
  unlink(tmp_dir, recursive = TRUE)
  
  # --- 5. Extract total application rate within each facility buffer ---------
  if (terra::crs(sf_obj) != terra::crs(total_sum)) {
    sf_obj <- sf::st_transform(sf_obj, crs = terra::crs(total_sum))
  }
  
  facilities_pest <- sf_obj %>%
    sf::st_buffer(dist = dist) %>%
    mutate(pesticide_mean_kg = exactextractr::exact_extract(
      total_sum, ., fun = "weighted_mean", weights = "area"
    )) %>%
    sf::st_drop_geometry() %>%
    dplyr::select(!!sym(id_column), pesticide_mean_kg)
  
  if (save) {
    readr::write_csv(facilities_pest, paste0(out_path, "/pesticides_", Sys.Date(), ".csv"))
  }
  
  return(facilities_pest)
}