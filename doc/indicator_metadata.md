Indicator Metatdata
================

<table style="width:99%;">
<colgroup>
<col style="width: 7%" />
<col style="width: 40%" />
<col style="width: 5%" />
<col style="width: 6%" />
<col style="width: 28%" />
<col style="width: 4%" />
<col style="width: 5%" />
</colgroup>
<tbody>
<tr class="odd">
<td>Indicator</td>
<td>Dataset used</td>
<td>Function / file name</td>
<td>Processing script (if applicable)</td>
<td>Indicator Description</td>
<td>Time frame / last updated</td>
<td>Spatial resolution (if raster)</td>
</tr>
<tr class="even">
<td>Heat exposure</td>
<td><a
href="https://developers.google.com/earth-engine/datasets/catalog/MODIS_061_MYD11A1#description">MODIS
daily land surface temperature</a></td>
<td>python/calc_myd11_lst_day.py</td>
<td>procces_data/process_lst.R</td>
<td>Mean daily LST for summer months (June-August) from the last 10
years (2013-2023) averaged within prison boundaries.</td>
<td>2013 - 2023</td>
<td>1 km</td>
</tr>
<tr class="odd">
<td>Canopy cover</td>
<td><a
href="https://developers.google.com/earth-engine/datasets/catalog/USGS_NLCD_RELEASES_2016_REL">USGS
National Land Cover Database</a></td>
<td>python/calc_canopy_cover.py</td>
<td></td>
<td>Average percent canopy cover within prison boundaries + 1km
buffer.</td>
<td>2016</td>
<td>30 m</td>
</tr>
<tr class="even">
<td>Wildfire risk</td>
<td><a
href="https://www.fs.usda.gov/rds/archive/catalog/RDS-2015-0047-3">Wildfire
Hazard Potential for the United States</a></td>
<td>calc_wildfire_risk.R</td>
<td></td>
<td>Mean wildfire hazard potential within prison boundary + 1km
buffer</td>
<td>2020</td>
<td>270 m</td>
</tr>
<tr class="odd">
<td>Flood risk</td>
<td><a
href="https://www.fema.gov/flood-maps/national-flood-hazard-layer">FEMA
National Flood Hazard Layer</a></td>
<td>calc_flood_risk.R</td>
<td></td>
<td>Percentage of each prison boundary + 1km buffer that is covered by a
high risk flood zone (Zones A and Z; at least a one percent chance of
flooding annually)</td>
<td>August 2021</td>
<td></td>
</tr>
<tr class="even">
<td>Ozone</td>
<td><a
href="https://sedac.ciesin.columbia.edu/data/set/aqdh-o3-concentrations-contiguous-us-1-km-2000-2016">SEDAC
Annual O3 Concentrations for CONUS</a></td>
<td>calc_ozone.R</td>
<td></td>
<td>Average annual ozone levels for 2015 and 2016 within prison
boundaries + 1km buffer</td>
<td>2015-2016</td>
<td>1 km</td>
</tr>
<tr class="odd">
<td>PM 2.5</td>
<td><a
href="https://sedac.ciesin.columbia.edu/data/set/aqdh-pm2-5-concentrations-contiguous-us-1-km-2000-2016">SEDAC
Annual PM2.5 Concentrations for CONUS</a></td>
<td>calc_pm25.R</td>
<td></td>
<td>Average annual PM2.5 levels for 2015 and 2016 within prison
boundaries + 1km buffer</td>
<td>2015-2016</td>
<td>1 km</td>
</tr>
<tr class="even">
<td>Traffic volume and proximity</td>
<td><a
href="https://www.fhwa.dot.gov/policyinformation/hpms/shapefiles.cfm">FHA’s
Annual Average Daily Traffic</a></td>
<td>calc_traffic_proximity.R</td>
<td>process_data/process_traffic.R</td>
<td>Count of vehicles (AADT, avg. annual daily traffic) at major roads
within 500 meters, divided by distance in meters</td>
<td>2018</td>
<td></td>
</tr>
<tr class="odd">
<td>Pesticide use</td>
<td><a
href="https://sedac.ciesin.columbia.edu/data/set/ferman-v1-pest-chemgrids-v1-01">SEDAC
Global Pesticide Grids</a></td>
<td>calc_pesticides.R</td>
<td></td>
<td>The total pesticide application from 2015 in kg/ha*yr averaged over
prison boundaries + 1km buffer.</td>
<td>2015</td>
<td>~ 10 km (5 arc-minute)</td>
</tr>
<tr class="even">
<td>Superfund/NPL proximity</td>
<td><a
href="https://cumulis.epa.gov/supercpad/CurSites/srchsites.cfm">EPA</a>
(click ‘View a list of all NPL and SAA sites’ then ‘Download Excel
file’)</td>
<td>calc_npl_proximity.R</td>
<td>process_data/process_npl.R</td>
<td>Count of proposed and listed NPL facilities within 5km (or nearest
one beyond 5km) each divided by the distance in km</td>
<td>October 2022</td>
<td></td>
</tr>
<tr class="odd">
<td>Risk Management Plan facility proximity</td>
<td><a
href="https://hifld-geoplatform.opendata.arcgis.com/datasets/geoplatform::epa-emergency-response-er-risk-management-plan-rmp-facilities/explore?location=29.842034%2C-113.806709%2C3.92">HIFLD
EPA ER Risk Management Plan Facilities</a></td>
<td>calc_rmp_proximity.R</td>
<td></td>
<td><p>Count of Risk Management Plan (potential chemical accident
management plan) facilities within 5km (or nearest one beyond 5km) each
divided by the distance in km.</p>
<p>Modeled after EJ Screen methods (pg. 21): <a
href="https://www.epa.gov/sites/default/files/2021-04/documents/ejscreen_technical_document.pdf"
class="uri">https://www.epa.gov/sites/default/files/2021-04/documents/ejscreen_technical_document.pdf</a></p></td>
<td>May 2023</td>
<td></td>
</tr>
<tr class="even">
<td>Hazardous waste facility proximity</td>
<td><a
href="https://www.epa.gov/frs/geospatial-data-download-service">EPA FRS
geospatial download</a> (Downloaded the National and State ALL FRS
single CSV file)</td>
<td>calc_haz_waste_proximity.R</td>
<td>process_data/process_haz_waste/R</td>
<td>Count of hazardous waste facilities within 5km of prison boundary
(or nearest beyond 5km) each divided by distance in km</td>
<td>March 2023</td>
<td></td>
</tr>
</tbody>
</table>
