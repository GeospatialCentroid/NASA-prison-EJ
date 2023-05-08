#' Calculate flood risk
#' 
#' This function calls flood zone data from the FEMA ArcGIS map services and calculates the
#' percent of each prison boundary + buffer is covered by high risk flood zones (zones A | Z)
#' 
#' @param prisons An sf object of all prison polygons to be assessed
#' @param dist The buffer distance (in meters) to add around prison boundaries
#' @param save Whether to save (TRUE) the resulting dataframe (as .csv) or not (FALSE)
#' @param path If `save = TRUE`, the file path to save the dataframe.
#' @param date A date tag to add to the file name to track versions. Default is current date
#' 
#' @return A tibble with total area and percent area flood risk zones cover the buffered prison boundary
getFloodRisk <- function(prisons, dist = 1000, save = TRUE, path = 'data/processed/', date = Sys.Date()){

  #check that crs is WGS 84 and if not transform it
  if (st_crs(prisons) != st_crs(4326)) {
    prisons <- st_transform(prisons, crs = 4326)
  }
  
  
  #get unique facility IDs
  prisonID <- unique(prisons$FACILITYID)
  
  
  #df to fill in area values
  df <- tibble(FACILITYID = character(),
               flood_risk_area_m2 = numeric(), 
               flood_risk_percent = numeric())
  
  #for each prison....
  for (i in 1:length(prisonID)) {
    
    #error handling
    tryCatch({
      
      df[i, "FACILITYID"] <- prisonID[i]
      
      boundary <- prisons %>%
        filter(FACILITYID == prisonID[i])
      
      ## buffer prison
      prison_buffer <- st_buffer(boundary, dist) %>% 
        st_make_valid()
      
      
      ## get bounding box
      bb <- st_bbox(prison_buffer)
      
      ## extract bbox
      bb.ordered <-  paste(bb[1], bb[2], bb[3], bb[4], sep = "%2C")
      
      ## construct URL
      url <-
        paste0(
          'https://hazards.fema.gov/gis/nfhl/rest/services/public/',
          'NFHL/MapServer/',
          28,
          '/query?',
          '&geometry=',
          bb.ordered,
          '&geometryType=esriGeometryEnvelope',
          '&outFields=*',
          '&returnGeometry=true',
          '&returnZ=false',
          '&returnM=false',
          '&returnExtentOnly=false',
          '&f=geoJSON'
        )
      
      
      ## read in floodplain
      floodHaz <- sf::read_sf(url) %>% 
        st_make_valid()
      
      
      #if no flood zones
      if (nrow(floodHaz) == 0) {
        df[i, "flood_risk_area_m2"] <- 0
        df[i, "flood_risk_percent"] <- 0
      } else {
        ## filter to zones that hve A or V in them - high-risk flood zones/1% flood prob https://floodpartners.com/flood-zones/
        floodRisk <- floodHaz %>%
          filter(stringr::str_detect(FLD_ZONE, 'A|V') &
                   FLD_ZONE != "AREA NOT INCLUDED") #not sure if 'area not included' is in fema raw data
        
        
        #if no high risk flood zones
        if (nrow(floodRisk) == 0) {
          df[i, "flood_risk_area_m2"] <- 0
          df[i, "flood_risk_percent"] <- 0
          
        } else {
          floodArea <- st_intersection(floodRisk, prison_buffer)
          
          # if no intersection
          if (nrow(floodArea) == 0) {
            df[i, "flood_risk_area_m2"] <- 0
            df[i, "flood_risk_percent"] <- 0
            
          } else {
            df[i, "flood_risk_area_m2"] <- as.numeric(sum(st_area(floodArea)))
            df[i, "flood_risk_percent"] <-
              as.numeric(sum(st_area(floodArea)) / st_area(prison_buffer) * 100)
            
          }
          
          
        }
        
        
      }
      
      
      
    }, error=function(e){cat("Prison=", prisonID[i], "Index=", i,
                              "ERROR :", conditionMessage(e), "\n")})
    
    
  }
  
  if (save == TRUE){
    
    write_csv(df, file = paste0(path,"/floodRisk_", date, ".csv"))
  }
  
  
  
}
