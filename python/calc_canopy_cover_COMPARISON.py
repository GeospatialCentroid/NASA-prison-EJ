# -*- coding: utf-8 -*-
"""
Created June 2026
Updated: for CA comparison analysis, CONUS only

@author: ccmothes
"""

# import and initialize earth engine

import ee
#ee.Authenticate()
ee.Initialize(project = "ee-ccmothes")

# Import new TCC dataset
dataset = ee.ImageCollection('USGS/NLCD_RELEASES/2023_REL/TCC/v2023-5')

# Filter to 2023 CONUS
nlcd_conus = dataset.filter(ee.Filter.eq('study_area', 'CONUS')) \
                    .filter(ee.Filter.eq('year', 2023)) \
                    .first() \
                    .select('NLCD_Percent_Tree_Canopy_Cover')

# Import ca sample polygons from GEE asset
ca_sample = ee.FeatureCollection("projects/ee-ccmothes/assets/ca_sample")

# Define reducer function
def canopy_conus(feature):
    canopy = nlcd_conus.reduceRegion(
              reducer=ee.Reducer.mean(),
              geometry=feature.geometry().buffer(1000),
              scale=30
    )
    return ee.Feature(None, canopy).set('object_id', feature.get('object_id'))

percent_canopy_conus = ca_sample.map(canopy_conus)

# Export CSV to Drive
task = ee.batch.Export.table.toDrive(
  collection=percent_canopy_conus,
  description='ca_sample_canopy_CONUS',
  fileFormat='CSV',
  selectors=['object_id', 'NLCD_Percent_Tree_Canopy_Cover']
)
task.start()