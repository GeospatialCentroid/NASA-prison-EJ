# -*- coding: utf-8 -*-
"""
Created on Thu Feb 16 13:13:56 2023

@author: ccmothes
"""

# set up earth engine
import ee
#ee.Authenticate()
ee.Initialize()

# import prisons
#prison_centroids = ee.FeatureCollection("projects/ee-ccmothes/assets/prison_centroids")


# define date range
startDate = "2012-01-01"
endDate = "2022-12-31"

# Define function to convert Kelvin to Celcius
def toCelciusDay(image):
  lst = image.select('LST_Day_1km').multiply(0.02).subtract(273.15)
  overwrite = True
  result = image.addBands(lst, ['LST_Day_1km'], overwrite)
  return result


# Quality mask; code adopted from https://spatialthoughts.com/2021/08/19/qa-bands-bitmasks-gee/
def bitwiseExtract(input, fromBit, toBit):
  maskSize = ee.Number(1).add(toBit).subtract(fromBit)
  mask = ee.Number(1).leftShift(maskSize).subtract(1)
  return input.rightShift(fromBit).bitwiseAnd(mask)


#Let's extract all pixels from the input image where
#Bits 0-1 <= 1 (LST produced of both good and other quality)
#Bits 2-3 = 0 (Good data quality)
#Bits 4-5 Ignore, any value is ok
#Bits 6-7 = 0 (Average LST error ≤ 1K)
def applyQaMask(image):
  lstDay = image.select('LST_Day_1km')
  qcDay = image.select('QC_Day')
  qaMask = bitwiseExtract(qcDay, 0, 1).lte(1)
  dataQualityMask = bitwiseExtract(qcDay, 2, 3).eq(0)
  lstErrorMask = bitwiseExtract(qcDay, 6, 7).lte(1)
  mask = qaMask.And(dataQualityMask).And(lstErrorMask)
  return lstDay.updateMask(mask)



#import MODIS
modisdata = ee.ImageCollection('MODIS/061/MYD11A1') \
  .filterDate(ee.Date(startDate),ee.Date(endDate)) \
  .filter(ee.Filter.calendarRange(6, 8,'month'))
  

#modisdata.first()
  
# Apply processing functions
lst_day_processed = modisdata.map(toCelciusDay).map(applyQaMask)
                                    #.map(clipped);
                                    
# Apply processing functions
lst_day_processed = modisdata.map(toCelciusDay).map(applyQaMask)

# Now calculate average summer day temperature across date range
summer_day_lst = lst_day_processed.select('LST_Day_1km').median()
                        
#print(summer_day_lst)

# Extract values at prison centroids
#sampled_points = summer_day_lst.sampleRegions(
#  collection=prison_centroids,
#  scale=1000,
#  geometries=True
#)     

# The sampleRegions method exceeds memory limits, use canopy cover method instead

## Import eeFeatureCollection from assets
prisons = ee.FeatureCollection("projects/ee-ccmothes/assets/study_prisons")

# reduce over prison polygons

## define function
def lst_calc(feature):
    lst = summer_day_lst.reduceRegion(
              reducer=ee.Reducer.mean(),
              geometry=feature.geometry(),
              scale=1000
    ) .set('FACILITYID',feature.get('FACILITYID'))
    return ee.Feature(None,lst)


prison_lst = prisons.map(lst_calc)
                   
                                    

# export to csv
task = ee.batch.Export.table.toDrive(
  collection = prison_lst,
  description='prison_lst',
  fileFormat='CSV',
  selectors=['FACILITYID', 'LST_Day_1km']
);

task.start()
