# -*- coding: utf-8 -*-
"""
Created on Thu Feb 23 11:00:09 2023

@author: ccmothes
"""

# import and initialize earth enginge

import ee
#ee.Authenticate()
ee.Initialize(project = "ee-ccmothes")

# Import new TCC dataset
dataset = ee.ImageCollection('USGS/NLCD_RELEASES/2023_REL/TCC/v2023-5')

# Filter to 2023 CONUS, AK and HI
nlcd_conus = dataset.filter(ee.Filter.eq('study_area', 'CONUS')) \
                    .filter(ee.Filter.eq('year', 2023)) \
                    .first() \
                    .select('NLCD_Percent_Tree_Canopy_Cover')

nlcd_AK = dataset.filter(ee.Filter.eq('study_area', 'AK')) \
                 .filter(ee.Filter.eq('year', 2023)) \
                 .first() \
                 .select('NLCD_Percent_Tree_Canopy_Cover')

nlcd_HI = dataset.filter(ee.Filter.eq('study_area', 'HAWAII')) \
                 .filter(ee.Filter.eq('year', 2023)) \
                 .first() \
                 .select('NLCD_Percent_Tree_Canopy_Cover')

# read in prisons and filter out conus, AK and HI

## Import eeFeatureCollection from assets
prisons = ee.FeatureCollection("projects/ee-ccmothes/assets/study_prisons_updated")

prisons_conus = prisons.filter("STATE != 'HI'").filter("STATE != 'AK'")
prisons_ak = prisons.filter("STATE == 'AK'")
prisons_hi = prisons.filter("STATE == 'HI'")

# Define reducer functions
def canopy_conus(feature):
    canopy = nlcd_conus.reduceRegion(
              reducer=ee.Reducer.mean(),
              geometry=feature.geometry().buffer(1000),
              scale=30
    ).set('FACILITYID', feature.get('FACILITYID'))
    return ee.Feature(None, canopy)

def canopy_ak(feature):
    canopy = nlcd_AK.reduceRegion(
              reducer=ee.Reducer.mean(),
              geometry=feature.geometry().buffer(1000),
              scale=30
    ).set('FACILITYID', feature.get('FACILITYID'))
    return ee.Feature(None, canopy)

def canopy_hi(feature):
    canopy = nlcd_HI.reduceRegion(
              reducer=ee.Reducer.mean(),
              geometry=feature.geometry().buffer(1000),
              scale=30
    ).set('FACILITYID', feature.get('FACILITYID'))
    return ee.Feature(None, canopy)

percent_canopy_conus = prisons_conus.map(canopy_conus)
percent_canopy_ak = prisons_ak.map(canopy_ak)
percent_canopy_hi = prisons_hi.map(canopy_hi)

# Export CSVs to Drive
task1 = ee.batch.Export.table.toDrive(
  collection=percent_canopy_conus,
  description='prison_canopy_CONUS',
  fileFormat='CSV',
  selectors=['FACILITYID', 'NLCD_Percent_Tree_Canopy_Cover']
)
task1.start()

task2 = ee.batch.Export.table.toDrive(
  collection=percent_canopy_ak,
  description='prison_canopy_AK',
  fileFormat='CSV',
  selectors=['FACILITYID', 'NLCD_Percent_Tree_Canopy_Cover']
)
task2.start()

task3 = ee.batch.Export.table.toDrive(
  collection=percent_canopy_hi,
  description='prison_canopy_HI',
  fileFormat='CSV',
  selectors=['FACILITYID', 'NLCD_Percent_Tree_Canopy_Cover']
)
task3.start()
