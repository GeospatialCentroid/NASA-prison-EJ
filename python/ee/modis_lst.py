# -*- coding: utf-8 -*-
"""
Created on Thu Feb 16 13:13:56 2023

@author: ccmothes
"""

import geemap
import ee
import pandas as pd
import os

#set wd to prison project
os.chdir('Desktop/NASA-prison-EJ/python')

#ee.Authenticate()
ee.Initialize()
#try:
#        ee.Initialize()
#except Exception as ee:
#        ee.Authenticate()
#        ee.Initialize()

# define CONUS region
region = ee.Geometry.BBox(-129.023438,24.447150,-66.093750,50.625073)


# define date range
startDate = "2012-01-01"
endDate = "2022-12-31"


#import MODIS
modisdata = ee.ImageCollection('MODIS/061/MYD11A1') \
  .filterBounds(region) \
  .filterDate(ee.Date(startDate),ee.Date(endDate)) \
  .filter(ee.Filter.calendarRange(6, 8,'month'))
  
  
# map one Modis layer
# add image to map
Map = geemap.Map(add_google_map=False, layer_ctrl=True)
#center around region of interest
Map.centerObject(region, zoom=11)

print(modisdata.first())
  
Map.addLayer(modisdata.first())
  
Map.save('map_test.html')
