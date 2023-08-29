# -*- coding: utf-8 -*-
"""
Created on Thu Feb 16 13:13:56 2023

@author: ccmothes
"""

# set up earth engine
import ee
# ee.Authenticate()
ee.Initialize()


# define date range
startDate = "2012-01-01"
endDate = "2022-12-31"

# Define function to convert Kelvin to Celcius


def toCelciusDay(image):
  lst = image.select('LST_Night_1km').multiply(0.02).subtract(273.15)
  overwrite = True
  result = image.addBands(lst, ['LST_Night_1km'], overwrite)
  return result


# Quality mask; code adopted from https://spatialthoughts.com/2021/08/19/qa-bands-bitmasks-gee/
def bitwiseExtract(input, fromBit, toBit):
  maskSize = ee.Number(1).add(toBit).subtract(fromBit)
  mask = ee.Number(1).leftShift(maskSize).subtract(1)
  return input.rightShift(fromBit).bitwiseAnd(mask)


# Let's extract all pixels from the input image where
# Bits 0-1 <= 1 (LST produced of both good and other quality)
# Bits 2-3 = 0 (Good data quality)
# Bits 4-5 Ignore, any value is ok
# Bits 6-7 <= 1 (Average LST error ≤ 2K)
def applyQaMask(image):
  lstNight = image.select('LST_Night_1km')
  qcNight = image.select('QC_Night')
  qaMask = bitwiseExtract(qcNight, 0, 1).eq(0)
  #dataQualityMask = bitwiseExtract(qcDay, 2, 3).eq(0)
  #cloudMask = bitwiseExtract(qcDay, 4, 5).eq(0)
  #lstErrorMask = bitwiseExtract(qcDay, 14, 15).gte(1)
  mask = qaMask
  return lstNight.updateMask(mask)


# import MODIS
modisdata = ee.ImageCollection('MODIS/061/MYD11A1') \
  .filterDate(ee.Date(startDate), ee.Date(endDate)) \
  .filter(ee.Filter.calendarRange(6, 8, 'month'))


# Apply processing functions
lst_night_processed = modisdata.map(toCelciusDay).map(applyQaMask)


# Import eeFeatureCollection from assets
prisons = ee.FeatureCollection("projects/ee-ccmothes/assets/prisons_1")



# New workflow from Justin Braaten: https://gis.stackexchange.com/questions/343696/calculate-mean-evi-for-multiple-polygons-across-an-image-collection-in-google-ea


def reduceRegions(image):
  LST_mean = (image
             .reduceRegions(
                 collection=prisons,
                 reducer=ee.Reducer.mean(),
                 scale=1000))
  # Return the featureCollection with the LST mean summary per feature, but
  # first...
  # map over the featureCollection to edit properties of each feature.

  def featureRefine(feature):
      return feature \
          .select(['mean', 'FACILITYID'], ['LST_mean_night', 'FACILITYID']) \
          .set('date', image.get('system:index'))
    
   # remove any features that have a null value for any property.        
  return LST_mean \
  .filter(ee.Filter.notNull(['mean'])) \
  .map(featureRefine)

# attempt to map over image collection
daily_mean_lst = lst_night_processed.map(reduceRegions).flatten()


#prison_lst = lst_day_processed_local.map(lst_calc).flatten()

#prison_lmtd = prison_lst.filter(ee.Filter.notNull(['LST_Day_mean']))

# export to csv
task = ee.batch.Export.table.toDrive(
  collection=daily_mean_lst,
  folder="gee_exports",
  description='prison_lst_daily_night',
  fileFormat='CSV'
  #selectors=['FACILITYID', 'LST_Day_mean', 'system:index']
)

task.start()
