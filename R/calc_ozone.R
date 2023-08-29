#' Calculate ozone risk
#'
#' This function calculates the ozone levels averaged within each prison boundary + buffer using the
#' SEDAC 1km CONUS Ozone dataset for 2000-2016
#'
#' @param sf_obj An sf object of all polygons to be assessed
#' @param folder The filepath to the folder with all the Ozone rasters (one for each month/year)
#' @param dist The buffer distance (in meters) to add around polygon boundaries
#' @param years The year range (given as a vector) to average Ozone over. Default is most recent available (2014-2016)
#' @param save Whether to save (TRUE) the resulting dataframe (as .csv) or not (FALSE)
#' @param out_path If `save = TRUE`, the file path to save the dataframe.
#'
#' @return A tibble with total mean ozone values for selected years within each buffered spatial boundary
calc_ozone <-
  function(sf_obj,
           folder,
           dist = 1000,
           years = c(2014, 2016),
           save = TRUE,
           out_path = "outputs/") {
    # import and calculate avg annual ozone for specified year range

    files <- list.files(folder, pattern = ".tif", full.names = TRUE)
    
    # loop over  years
    out <- vector("list", length = length(years))
    
    for (i in 1:length(years)){
      
      daily <- files %>%
        purrr::keep(grepl('2014', files)) %>%
        map(rast) %>%
        # stack all rasters (rast() works as stack() in terra)
        rast()
      
      # calculate 4th highest value for each pixel
      out[[i]] <- terra::app(daily, fun=function(X,na.rm) X[order(X,decreasing=T)[4]])
      
      
    }

    #get values averaged across all 3 years
    mean_ozone <- terra::rast(out) %>% 
      mean()


    # buffer prisons by dist
    sf_buff <- sf_obj %>%
      st_buffer(dist = dist)

    # check if CRS match, if not transform prisons
    if (crs(sf_obj) != crs(mean_ozone)) {
      sf_buff <- st_transform(sf_buff, crs = crs(mean_ozone))
    }


    # calculate average ozone within each buffer
    sf_buff$mean_ozone <- terra::extract(mean_ozone, sf_buff, fun = "mean", na.rm = TRUE)[, 2]

    # clean dataset to return just prison ID and calculated value
    sf_ozone <- sf_buff %>%
      st_drop_geometry() %>%
      select(FACILITYID, mean_ozone)



    if (save == TRUE) {
      write_csv(sf_ozone, file = paste0(out_path, "/ozone_", Sys.Date(), ".csv"))
    }


    return(sf_ozone)
  }
