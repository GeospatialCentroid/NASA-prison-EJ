# -*- coding: utf-8 -*-
"""
Created on Thu Feb 23 11:00:09 2023

@author: ccmothes
"""

# import and initialize earth enginge

import ee
#ee.Authenticate()
ee.Initialize()

# Import nlcd dataset
dataset = ee.ImageCollection('USGS/NLCD_RELEASES/2016_REL')


# filter NLCD to 2016 CONUS, AK and HI
nlcd_conus = dataset.filter(ee.Filter.eq('system:index', '2016')).first().select('percent_tree_cover')

nlcd_AK = dataset.filter(ee.Filter.eq('system:index', '2016_AK')).first().select('percent_tree_cover')

nlcd_HI = dataset.filter(ee.Filter.eq('system:index', '2016_HI')).first().select('percent_tree_cover')


# read in prisons and filter out conus, AK and HI

## Import eeFeatureCollection from assets
prisons = ee.FeatureCollection("projects/ee-ccmothes/assets/study_prisons")

prisons_conus = prisons.filter("STATE != 'HI'").filter("STATE != 'AK'")

prisons_ak = prisons.filter("STATE == 'AK'")

prisons_hi = prisons.filter("STATE == 'HI'")


# reduce over prison polygons w/ 1km buffer

## define functions
def canopy_conus(feature):
    canopy = nlcd_conus.reduceRegion(
              reducer=ee.Reducer.mean(),
              geometry=feature.geometry().buffer(1000),
              scale=30
    ) .set('FACILITYID',feature.get('FACILITYID'))
    return ee.Feature(None,canopy)


def canopy_ak(feature):
    canopy = nlcd_AK.reduceRegion(
              reducer=ee.Reducer.mean(),
              geometry=feature.geometry().buffer(1000),
              scale=30
    ) .set('FACILITYID',feature.get('FACILITYID'))
    return ee.Feature(None,canopy)


def canopy_hi(feature):
    canopy = nlcd_HI.reduceRegion(
              reducer=ee.Reducer.mean(),
              geometry=feature.geometry().buffer(1000),
              scale=30
    ) .set('FACILITYID',feature.get('FACILITYID'))
    return ee.Feature(None,canopy)


percent_canopy_conus = prisons_conus.map(canopy_conus)

percent_canopy_ak = prisons_ak.map(canopy_ak)

percent_canopy_hi = prisons_hi.map(canopy_hi)


# export csvs to Drive

## conus
task1 = ee.batch.Export.table.toDrive(
  collection = percent_canopy_conus,
  description='prison_canopy_CONUS',
  fileFormat='CSV',
  selectors=['FACILITYID', 'percent_tree_cover']
);

task1.start()

## alaska
task2 = ee.batch.Export.table.toDrive(
  collection = percent_canopy_ak,
  description='prison_canopy_AK',
  fileFormat='CSV',
  selectors=['FACILITYID', 'percent_tree_cover']
);

task2.start()

## hawaii
task3 = ee.batch.Export.table.toDrive(
  collection = percent_canopy_hi,
  description='prison_canopy_HI',
  fileFormat='CSV',
  selectors=['FACILITYID', 'percent_tree_cover']
);

task3.start()
