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

Reduction strategy: annual summer composites (mean + count) per prison polygon.
One reduceRegions call per year rather than per image for performance.

@author: ccmothes (updated from MODIS to Landsat)
"""

# set up earth engine
import ee
# ee.Authenticate()
ee.Initialize(project="ee-ccmothes")


# ---- Configuration --------------------------------------------------------

# Years to process
years = list(range(2019, 2026))  # 2019, 2020, 2021, 2022, 2023, 2024, 2025

# Summer month filter (June-August)
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
    cloud_shadow  = 1 << 3
    snow          = 1 << 4
    cloud         = 1 << 5

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


# ---- Import prison FeatureCollection from assets ---------------------------

prisons = ee.FeatureCollection("projects/ee-ccmothes/assets/study_prisons_updated")


# ---- Build annual composites and reduce ------------------------------------

def process_year(year):
    """
    For a given year, build a summer LST composite (mean + count),
    reduce over prison polygons, and return a FeatureCollection with
    LST_mean, n_images, FACILITYID, and year.
    """
    start = f"{year}-06-01"
    end   = f"{year}-08-31"

    # Landsat 8
    l8 = (ee.ImageCollection('LANDSAT/LC08/C02/T1_L2')
          .filterDate(start, end)
          .filter(ee.Filter.calendarRange(summerStart, summerEnd, 'month'))
          .filter(ee.Filter.eq('PROCESSING_LEVEL', 'L2SP')))

    # Landsat 9
    l9 = (ee.ImageCollection('LANDSAT/LC09/C02/T1_L2')
          .filterDate(start, end)
          .filter(ee.Filter.calendarRange(summerStart, summerEnd, 'month'))
          .filter(ee.Filter.eq('PROCESSING_LEVEL', 'L2SP')))

    # Merge and apply QA/scaling pipeline
    processed = (l8.merge(l9)
                 .map(cloudMask)
                 .map(applySTScaleFactors)
                 .map(applySTQualityMask))

    # Annual mean LST and pixel-wise image count (non-masked pixels)
    mean_img  = processed.mean().rename('LST_mean')
    count_img = processed.count().rename('n_images')

    composite = mean_img.addBands(count_img).set('year', year)

    # Single reduceRegions call for this year
    reduced = composite.reduceRegions(
        collection=prisons,
        reducer=ee.Reducer.mean(),  # applies to both bands
        scale=30                    # Landsat native resolution
    )

    # Rename output bands, attach year, drop null results
    def refine(feature):
        return (feature
                .select(['LST_mean', 'n_images', 'FACILITYID'])
                .set('year', year))

    return (reduced
            .filter(ee.Filter.notNull(['LST_mean']))
            .map(refine))


# ---- Process all years and merge ------------------------------------------

all_years = [process_year(y) for y in years]

# Report collection sizes before export (optional — remove if slow)
for y, fc in zip(years, all_years):
    print(f"{y}: {fc.size().getInfo()} features")

annual_lst = ee.FeatureCollection(all_years).flatten()


# ---- Export to CSV ---------------------------------------------------------

task = ee.batch.Export.table.toDrive(
    collection=annual_lst,
    folder="gee_exports",
    description='prison_lst_landsat_annual_summer_2019_2025',
    fileFormat='CSV'
)

task.start()

print("Export task submitted: prison_lst_landsat_annual_summer_2019_2025")
print("Check status at: https://code.earthengine.google.com/tasks")