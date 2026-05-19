#' Calculate Flood Risk
#' 
#' Calculates flood sensitivity using current FEMA flood zone maps. Returns total area and % cover of
#' high risk flood zones (those with A or V categories) within a given polygon + buffer. This indicates
#' a 1% annual chance of flooding.
#' 
#' Pulls from FEMA WMS endpoint at: https://hazards.fema.gov/arcgis/rest/services/public/NFHL/MapServer
#' 
#' @param sf_obj sf object with polygons of interest
#' @param dist distance (in meters) of buffer
#' @param save logical, whether to save output
#' @param out_path character, directory path for saving files
#' @param verbose logical, whether to show progress messages
#' 
#' @return tibble with FACILITY ID and flood risk values. Returns 'NA' where FEMA data is not
#' available, and 0 when it is available but there are no high risk flood zones in the buffer.
#' 
calc_flood_risk <-
  function(sf_obj,
           dist = 1000,
           save = FALSE,
           out_path = NULL,
           verbose = TRUE) {
    
    # Input validation
    stopifnot(
      "sf_obj must be an sf object" = inherits(sf_obj, "sf"),
      "save is TRUE but output_dir not provided" = !save ||
        !is.null(output_dir)
    )
    
    # buffer polygons to specified distance
    sf_obj <- sf_obj %>% 
      st_buffer(dist = dist)
    
    # match CRS to that of FEMA flood layer
    if (st_crs(sf_obj) != st_crs(4269)) {
      sf_obj <- st_transform(sf_obj, crs = 4269)
    }
    
    # Start timing
    start_time <- Sys.time()
    
    # Create progress bar
    if (verbose) {
      pb <- progress::progress_bar$new(
        format = "Processing flood risk [:bar] :percent (:current/:total) ETA: :eta",
        total = nrow(sf_obj),
        clear = FALSE,
        width = 80
      )
    }
    
    # for each polygon....
    final_results <-  map_dfr(seq_len(nrow(sf_obj)), function(i) {
      if (verbose) pb$tick()
      
      
      boundary <- sf_obj[i, ]
      
      ## get bounding box
      bb <- st_bbox(boundary)
      
      ## extract bbox numbers
      bb.ordered <- paste(bb[1], bb[2], bb[3], bb[4], sep = "%2C")
      
      ## construct URL (OG version)
      url <- paste0(
        "https://hazards.fema.gov/arcgis/rest/services/public/NFHL/MapServer/",
        28,
        "/query?",
        "&geometry=",
        bb.ordered,
        "&geometryType=esriGeometryEnvelope",
        "&outFields=*",
        "&returnGeometry=true",
        "&returnZ=false",
        "&returnM=false",
        "&returnExtentOnly=false",
        "&f=geoJSON"
      )
      
      
      ## read in floodplain with error handling
      floodHaz <- tryCatch(
        {
          sf::read_sf(url) %>%
            st_make_valid()
        },
        error = function(e) {
          if (verbose) {
            message("\nWarning: Unable to read flood data for ",
                    sf_obj[i, ]$FACILITYID)
          }
          # Return NULL to indicate error
          return(NULL)
        }
      )
      
      # if error occurred during read
      if (is.null(floodHaz)) {
        df <- tibble(
          FACILITYID = sf_obj[i, ]$FACILITYID,
          flood_risk_area_m2 = NA,
          flood_risk_percent = NA
        )
        
      } else if (nrow(floodHaz) == 0) {
        df <- tibble(
          FACILITYID = sf_obj[i, ]$FACILITYID,
          flood_risk_area_m2 = NA,
          flood_risk_percent = NA
        )
        
      } else {
        ## filter to zones that hAve A or V in them - high-risk flood zones/1% flood prob https://floodpartners.com/flood-zones/
        floodRisk <- floodHaz %>%
          filter(stringr::str_detect(FLD_ZONE, "A|V") &
                   FLD_ZONE != "AREA NOT INCLUDED") # not sure if 'area not included' is in fema raw data
        
        
        # if no high risk flood zones
        if (nrow(floodRisk) == 0) {
          df <- tibble(
            FACILITYID = sf_obj[i, ]$FACILITYID,
            flood_risk_area_m2 = 0,
            flood_risk_percent = 0
          )
        } else {
          # match CRS
          boundary <- st_transform(boundary, st_crs(floodRisk))
          
          # Set attribute-geometry relationship to suppress warning
          st_agr(floodRisk) <- "constant"
          st_agr(boundary) <- "constant"
          
          # return overlapping areas
          floodArea <- st_intersection(floodRisk, boundary)
          
          # if no intersection
          if (nrow(floodArea) == 0) {
            df <- tibble(
              FACILITYID = sf_obj[i, ]$FACILITYID,
              flood_risk_area_m2 = 0,
              flood_risk_percent = 0
            )
          } else {
            df <- tibble(
              FACILITYID = sf_obj[i, ]$FACILITYID,
              flood_risk_area_m2 = as.numeric(sum(st_area(
                floodArea
              ))),
              flood_risk_percent = as.numeric(sum(st_area(
                floodArea
              )) / st_area(boundary) * 100)
            )
            
          }
          return(df)
        }
        
      }
    }
    )
    
    # Save results
    if (save) {
      if (!dir.exists(output_dir))
        dir.create(output_dir, recursive = TRUE)
      
      filename <- file.path(output_dir,
                            paste0("flood_risk_", Sys.Date(), ".csv"))
      write_csv(final_results, filename)
      
      if (verbose) {
        message("Results saved to: ", filename)
      }
    }
    
    # Print timing
    if (verbose) {
      end_time <- Sys.time()
      total_time <- end_time - start_time
      message(
        "\nFlood risk processing completed in ",
        round(total_time, 2),
        " ",
        attr(total_time, "units")
      )
    }
    
    return(final_results)
    
  }
