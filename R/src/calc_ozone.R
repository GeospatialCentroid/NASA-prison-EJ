#' Calculate ozone risk
#'
#' This function calculates the ozone levels averaged within each prison boundary + buffer using the
#' SEDAC 1km CONUS Ozone dataset for 2000-2016
#'
#' @param sf_obj An sf object of all polygons to be assessed
#' @param folder The filepath to the folder with all the Ozone rasters (one for each year)
#' @param dist The buffer distance (in meters) to add around polygon boundaries
#' @param years The year range (given as a vector) to average Ozone over. Must be within 2000-2016
#' @param save Whether to save (TRUE) the resulting dataframe (as .csv) or not (FALSE)
#' @param out_path If `save = TRUE`, the file path to save the dataframe.
#'
#' @return A tibble with total mean ozone values for selected years within each buffered spatial boundary
calc_ozone <-
  function(sf_obj,
           folder,
           dist = 5000,
           years = c(2000, 2016),
           save = TRUE,
           path = "outputs/") {
    # import and calculate avg annual ozone for specified year range

    files <- list.files(folder, pattern = ".tif", full.names = TRUE)

    avg_ozone <- paste0(as.character(years[1]:years[2]), ".tif") %>%
      map_chr(~ str_subset(files, .x)) %>%
      terra::rast() %>%
      mean()


    # buffer prisons by dist
    sf_buff <- sf_obj %>%
      st_buffer(dist = dist)

    # check if CRS match, if not transform prisons
    if (crs(sf_obj) != crs(avg_ozone)) {
      sf_buff <- st_transform(sf_buff, crs = crs(avg_ozone))
    }


    # calculate average ozone within each buffer
    sf_buff$avg_ozone <- terra::extract(avg_ozone, sf_buff, fun = "mean", na.rm = TRUE)[, 2]

    # clean dataset to return just prison ID and calculated value
    sf_ozone <- sf_buff %>%
      st_drop_geometry() %>%
      select(FACILITYID, avg_ozone)



    if (save == TRUE) {
      write_csv(sf_ozone, file = paste0(out_path, "/ozone_", Sys.Date(), ".csv"))
    }


    return(sf_ozone)
  }
