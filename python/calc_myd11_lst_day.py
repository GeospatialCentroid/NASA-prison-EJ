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
startDate = "2013-01-01"
endDate = "2023-08-31"

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


# Let's extract all pixels from the input image where
# Bits 0-1 <= 1 (LST produced of both good and other quality)
# Bits 2-3 = 0 (Good data quality)
# Bits 4-5 Ignore, any value is ok
# Bits 6-7 <= 1 (Average LST error ≤ 2K)
def applyQaMask(image):
  lstDay = image.select('LST_Day_1km')
  qcDay = image.select('QC_Day')
  qaMask = bitwiseExtract(qcDay, 0, 1).lte(1)
  dataQualityMask = bitwiseExtract(qcDay, 2, 3).eq(0)
  #cloudMask = bitwiseExtract(qcDay, 4, 5).eq(0)
  lstErrorMask = bitwiseExtract(qcDay, 6, 7).eq(0)
  mask = qaMask.And(dataQualityMask).And(lstErrorMask)
  return lstDay.updateMask(mask)


# import MODIS
modisdata = ee.ImageCollection('MODIS/061/MYD11A1') \
  .filterDate(ee.Date(startDate), ee.Date(endDate)) \
  .filter(ee.Filter.calendarRange(6, 8, 'month'))


# Apply processing functions
lst_day_processed = modisdata.map(toCelciusDay).map(applyQaMask)

# Now calculate average summer day temperature across date range
# summer_day_lst = lst_day_processed.select('LST_Day').median()

# Caluclate number of extreme heat days
# def hotdays(image):
#        hot = image.gt("LST_Day", 35)
#        return image.addBands(hot.rename('hotdays')
#                              .set('system:time_start', image.get('system:time_start')))

# lst_hotdays = ee.ImageCollection(lst_day_processed.select('LST_Day')).map(hotdays)

# lst_hotdays_2012 = ee.ImageCollection(lst_hotdays.select('hotdays')).sum().float()

# Import eeFeatureCollection from assets
prisons = ee.FeatureCollection("projects/ee-ccmothes/assets/study_prisons")

# filter lst for bounds of prisons
# lst_day_processed_local = (lst_day_processed.filterBounds(prisons.geometry()))

# reduce over prison polygons

# define funciton to drop geo


# def remove_geo(image):
#     return image.setGeometry(None)

# # define function


# def lst_calc(image):
#     lst = (image
#         .select(['LST_Day'], ['LST_Day_mean'])
#         .reduceRegions(
#               reducer=ee.Reducer.mean(),
#               collection=prisons,
#               # crs = "EPSG:4326",
#               scale=1000
#               ))
#     return lst.map(remove_geo)



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
          .select(['mean', 'FACILITYID'], ['LST_mean', 'FACILITYID']) \
          .set('date', image.get('system:index'))
    
   # remove any features that have a null value for any property.        
  return LST_mean \
  .filter(ee.Filter.notNull(['mean'])) \
  .map(featureRefine)

# attempt to map over image collection
daily_mean_lst = lst_day_processed.map(reduceRegions).flatten()


#prison_lst = lst_day_processed_local.map(lst_calc).flatten()

#prison_lmtd = prison_lst.filter(ee.Filter.notNull(['LST_Day_mean']))

# export to csv
# Note to change description for each prison chunk
task = ee.batch.Export.table.toDrive(
  collection=daily_mean_lst,
  folder="gee_exports",
  description='prison_lst_daily_all_2023-08-30',
  fileFormat='CSV'
  #selectors=['FACILITYID', 'LST_Day_mean', 'system:index']
)

task.start()
