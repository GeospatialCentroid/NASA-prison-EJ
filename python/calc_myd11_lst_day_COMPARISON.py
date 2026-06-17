# -*- coding: utf-8 -*-
"""
Created June 2026
Updated: for CA comparison group analysis

@author: ccmothes
"""

# set up earth engine
import ee
# ee.Authenticate()
ee.Initialize(project = "ee-ccmothes")


# define date range
startDate = "2023-06-01"
endDate = "2025-08-31"

# Define function to convert Kelvin to Celsius
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


# Extract all pixels where:
# Bits 0-1 <= 1 (LST produced of both good and other quality)
# Bits 2-3 = 0 (Good data quality)
# Bits 4-5 Ignore, any value is ok
# Bits 6-7 <= 1 (Average LST error <= 2K)
def applyQaMask(image):
  lstDay = image.select('LST_Day_1km')
  qcDay = image.select('QC_Day')
  qaMask = bitwiseExtract(qcDay, 0, 1).lte(1)
  dataQualityMask = bitwiseExtract(qcDay, 2, 3).eq(0)
  lstErrorMask = bitwiseExtract(qcDay, 6, 7).lte(1)
  mask = qaMask.And(dataQualityMask).And(lstErrorMask)
  return lstDay.updateMask(mask)


# import MODIS
modisdata = ee.ImageCollection('MODIS/061/MYD11A1') \
  .filterDate(ee.Date(startDate), ee.Date(endDate)) \
  .filter(ee.Filter.calendarRange(6, 8, 'month'))


# Apply processing functions
lst_day_processed = modisdata.map(applyQaMask).map(toCelciusDay)


# Import CA sample polygons from GEE asset
ca_sample = ee.FeatureCollection("projects/ee-ccmothes/assets/ca_sample")


def reduceRegions(image):
  
  LST_mean = (image
             .reduceRegions(
                 collection=ca_sample,
                 reducer=ee.Reducer.mean(),
                 scale=1000))

  def featureRefine(feature):
      return feature \
          .select(['mean'], ['LST_mean']) \
          .set('object_id', feature.get('object_id')) \
          .set('date', image.get('system:index'))

  return LST_mean \
  .filter(ee.Filter.notNull(['mean'])) \
  .map(featureRefine)


# Map over image collection
daily_mean_lst = lst_day_processed.map(reduceRegions).flatten()


# Export to CSV
task = ee.batch.Export.table.toDrive(
  collection=daily_mean_lst,
  folder="gee_exports",
  description='ca_comparison_lst_daily_MODIS_2026-06-17',
  fileFormat='CSV'
)

task.start()