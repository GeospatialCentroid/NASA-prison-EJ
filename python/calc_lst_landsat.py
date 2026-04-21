# -*- coding: utf-8 -*-
"""
calc_landsat_lst_day.py

Updated LST workflow using Landsat 8/9 Collection 2 Level-2
Surface Temperature (ST_B10) for summer months 2022-2025.

Replaces the earlier MODIS MYD11A1-based workflow.

Landsat C2 L2 ST_B10 scaling:
  Temperature (K) = DN * 0.00341802 + 149.0
  Temperature (C) = Temperature (K) - 273.15

QA masking uses QA_PIXEL bitmask:
  Bit 1 (Dilated Cloud), Bit 3 (Cloud Shadow), Bit 4 (Snow),
  Bit 5 (Cloud) — all must be 0 for clear pixels.
  Also filter to PROCESSING_LEVEL == 'L2SP' to ensure ST band is populated.

@author: ccmothes (updated from MODIS to Landsat)
"""

# set up earth engine
import ee
# ee.Authenticate()
ee.Initialize(project = "ee-ccmothes")


# ---- Configuration --------------------------------------------------------

# Date range: summer months June-August, 2022-2025
startDate = "2019-06-01"
endDate = "2025-08-31"

# Summer month filter
summerStart = 6
summerEnd = 8

# ---- Scale factors for Landsat Collection 2 Level-2 -----------------------

ST_SCALE = 0.00341802
ST_OFFSET = 149.0


# ---- Cloud / QA masking ---------------------------------------------------

def cloudMask(image):
    """Mask clouds, cloud shadows, snow, and dilated clouds using QA_PIXEL."""
    qa = image.select('QA_PIXEL')
    # Bits: 1=Dilated Cloud, 3=Cloud Shadow, 4=Snow, 5=Cloud
    dilated_cloud = 1 << 1
    cloud_shadow = 1 << 3
    snow = 1 << 4
    cloud = 1 << 5

    mask = (qa.bitwiseAnd(dilated_cloud).eq(0)
            .And(qa.bitwiseAnd(cloud_shadow).eq(0))
            .And(qa.bitwiseAnd(snow).eq(0))
            .And(qa.bitwiseAnd(cloud).eq(0)))
    return image.updateMask(mask)


# ---- Apply ST scaling and convert to Celsius --------------------------------

def applySTScaleFactors(image):
    """Apply Collection 2 scale/offset to ST_B10 and convert K -> C."""
    st_kelvin = image.select('ST_B10').multiply(ST_SCALE).add(ST_OFFSET)
    st_celsius = st_kelvin.subtract(273.15).rename('LST_Day')
    return image.addBands(st_celsius)


# ---- Quality filter using ST_QA band ---------------------------------------

def applySTQualityMask(image):
    """Mask pixels with high ST uncertainty (ST_QA > 2.5 K, i.e., DN > ~733).
    ST_QA is scaled by 0.01 to get uncertainty in Kelvin.
    Keep pixels where uncertainty <= 2.5 K."""
    st_qa = image.select('ST_QA').multiply(0.01)
    quality_mask = st_qa.lte(2.5)
    return image.select('LST_Day').updateMask(quality_mask)


# ---- Import Landsat 8 and 9 ------------------------------------------------

# Landsat 8 (April 2013 - present)
landsat8 = (ee.ImageCollection('LANDSAT/LC08/C02/T1_L2')
            .filterDate(ee.Date(startDate), ee.Date(endDate))
            .filter(ee.Filter.calendarRange(summerStart, summerEnd, 'month'))
            .filter(ee.Filter.eq('PROCESSING_LEVEL', 'L2SP')))

# Landsat 9 (Feb 2022 - present)
landsat9 = (ee.ImageCollection('LANDSAT/LC09/C02/T1_L2')
            .filterDate(ee.Date(startDate), ee.Date(endDate))
            .filter(ee.Filter.calendarRange(summerStart, summerEnd, 'month'))
            .filter(ee.Filter.eq('PROCESSING_LEVEL', 'L2SP')))

# Merge Landsat 8 and 9 into a single collection
landsat_merged = landsat8.merge(landsat9)

print(f"Total Landsat 8+9 images (summer {startDate} to {endDate}): "
      f"{landsat_merged.size().getInfo()}")


# ---- Apply processing functions --------------------------------------------

lst_day_processed = (landsat_merged
                     .map(cloudMask)
                     .map(applySTScaleFactors)
                     .map(applySTQualityMask))


# ---- Import prison FeatureCollection from assets ---------------------------

prisons = ee.FeatureCollection("projects/ee-ccmothes/assets/study_prisons_updated")


# ---- Reduce over prison polygons ------------------------------------------

def reduceRegions(image):
    """Calculate mean LST per prison polygon for a single image."""
    LST_mean = image.reduceRegions(
        collection=prisons,
        reducer=ee.Reducer.mean(),
        scale=30  # Landsat native resolution
    )

    def featureRefine(feature):
        return (feature
                .select(['mean', 'FACILITYID'], ['LST_mean', 'FACILITYID'])
                .set('date', image.get('system:index')))

    # Remove features with null mean (no valid pixels in polygon)
    return (LST_mean
            .filter(ee.Filter.notNull(['mean']))
            .map(featureRefine))


# Map over image collection and flatten
daily_mean_lst = lst_day_processed.map(reduceRegions).flatten()


# ---- Export to CSV ---------------------------------------------------------

task = ee.batch.Export.table.toDrive(
    collection=daily_mean_lst,
    folder="gee_exports",
    description='prison_lst_landsat_daily_summer_2019_2025',
    fileFormat='CSV'
)

task.start()

print("Export task submitted: prison_lst_landsat_daily_summer_2019_2025")
print(f"Check status at: https://code.earthengine.google.com/tasks")