#' Process PM2.5 
#' 
#' This file converts the annual mean PM2.5 surface concentrations from 'V5.GL.04'of
#' of the dataset developed by van Donkelaar et. all (2021) from type 'NetCDF' to 
#' 'TIF.'
#' 
#' input_dir The filepath to the folder with all the PM2.5 nc files
#' output_dir The filepath to the folder all PM2.5 rasters will be saved
#' 

library(ncdf4) #required to manipulate NetCDF files

input_dir <-  'data/phase2/raw/PM2.5'
output_dir <-  'data/phase2/processed/PM2.5'

#generate a list of all file paths in input directory
list.files(path = input_dir, pattern = "\\.nc$", full.names = TRUE) %>% 
  walk(function(path){
    #record what year we are dealing with
    year <- str_extract(basename(path),"\\d{7}") %>% str_sub(1,4)
    
    #write raster
    r <- rast(path)
    
    #save raster to output directory
    writeRaster(r,
                file.path(output_dir,paste0("pm25_",year,".tif")),
                overwrite = TRUE)
  })


    