import ee
import folium
import numpy as np
from IPython.display import display

# pylint: disable=protected-access

# Authenticate to the Earth Engine API
# ee.Authenticate()
ee.Initialize()

# Define the study area
study_area = ee.Geometry.Rectangle([-126.4, 24.5, -66.9, 49.1])

# Create an ImageCollection of Landsat 8 data
landsat8_collection = ee.ImageCollection('LANDSAT/LC08/C01/T1_SR')

# Filter the collection to the study area and a specific time period
landsat8_collection = landsat8_collection.filterBounds(study_area).filterDate('2018-01-01', '2018-12-31')

# Define the temperature and humidity bands
temp_band = 'B11'
humidity_band = 'B9'

# Define the heat index equation
# def heat_index(T, H):
#     c1 = -42.379
#     c2 = 2.04901523
#     c3 = 10.14333127
#     c4 = -0.22475541
#     c5 = -6.83783e-03
#     c6 = -5.481717e-02
#     c7 = 1.22874e-03
#     c8 = 8.5282e-04
#     c9 = -1.99e-06
#     T2 = T.pow(2)
#     H2 = H.pow(2)
#     return c1 + T.multiply(c2) + H.multiply(c3) + T.multiply(H).multiply(c4) + T.multiply(c5) + H2.multiply(c6) + T2.multiply(H).multiply(c7) + T.multiply(H2).multiply(c8) + T2.multiply(H2).multiply(c9)

## Iteration 1
# Apply the heat index equation to the image collection
# heat_index_collection = landsat8_collection.map(lambda image: image.expression('heat_index = heat_index(temp_band, humidity_band)'))
#
# heat_index_collection_select = landsat8_collection.map(lambda image:
#     {
#         'temp_band': image.select(temp_band),
#         'humidity_band': image.select(humidity_band),
#         'heat_index': heat_index
#     }
# )
#

## Iteration 1.5
# heat_index_collection = landsat8_collection.map(lambda image: image.expression(
#     'heat_index = heat_index(temp_band, humidity_band)',
#     {
#         'temp_band': image.select(temp_band),
# #       'humidity_band': image.select(humidity_band),
#         'heat_index': heat_index
#     }
# ))

## Iteration 2
# heat_index_collection = landsat8_collection.map(lambda image: image.addBands(
#     image.expression(
#         'heat_index_band = heat_index(temp_band, humidity_band)',
#         {'temp_band': image.select(temp_band),
#          'humidity_band': image.select(humidity_band),
#          'heat_index': 'heat_index'}
#     )
# ))

# Iteration 3: accounts for function capabilities
c1 = -42.379
c2 = 2.04901523
c3 = 10.14333127
c4 = -0.22475541
c5 = -6.83783e-03
c6 = -5.481717e-02
c7 = 1.22874e-03
c8 = 8.5282e-04
c9 = -1.99e-06

heat_index_collection = landsat8_collection.map(lambda image: image.addBands(
    ee.Image(
        ((image.select(temp_band)).multiply(c2)).add(c1),
    ).rename(['heat_index']),
))

heat_index_collection = landsat8_collection.map(lambda image: image.addBands(
    image.expression(
        'c1 + c2*temp_band + c3*humidity_band + c4*temp_band.multiply(humidity_band) + c5*temp_band.pow(2) + c6*humidity_band.pow(2) + c7*temp_band.pow(2).multiply(humidity_band) + c8*temp_band.multiply(humidity_band).pow(2) + c9*temp_band.pow(2).multiply(humidity_band).pow(2)',
        {
            'humidity_band': image.select(humidity_band),
            'temp_band': image.select(temp_band),
            'c1': -42.379,
            'c2': 2.04901523,
            'c3': 10.14333127,
            'c4': -0.22475541,
            'c5': -6.83783e-03,
            'c6': -5.481717e-02,
            'c7': 1.22874e-03,
            'c8': 8.5282e-04,
            'c9': -1.99e-06
        }
    ).rename(['heat_index']),
))


# Get the median heat index value for each pixel
heat_index_image = heat_index_collection.median()

# Get the map ID and token for the heat index image
heat_index_mapid = heat_index_image.getMapId()
heat_index_token = heat_index_mapid['token']

# Create a folium map
m = folium.Map(location=[39.828, -98.579], zoom_start=4)

# Add the heat index image to the map
folium.TileLayer(
    tiles='https://earthengine.googleapis.com/map/{mapid}/{{z}}/{{x}}/{{y}}?token={token}'.format(
        mapid=heat_index_mapid['mapid'],
        token=heat_index_token),
    attr='Google Earth Engine',
    overlay=True,
    name='Heat Index',
    control=False
).add_to(m)

m.save('heat_index_map.html')
