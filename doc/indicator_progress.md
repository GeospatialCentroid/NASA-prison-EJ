Indicator Progress Tracker
================

<table style="width:99%;">
<colgroup>
<col style="width: 6%" />
<col style="width: 43%" />
<col style="width: 6%" />
<col style="width: 32%" />
<col style="width: 3%" />
<col style="width: 2%" />
<col style="width: 2%" />
<col style="width: 1%" />
</colgroup>
<tbody>
<tr class="odd">
<td>Indicator</td>
<td>Dataset used</td>
<td>Function/file name</td>
<td>Task</td>
<td>Charged to:</td>
<td>In progress</td>
<td>Needs review</td>
<td>Done</td>
</tr>
<tr class="even">
<td>Heat index</td>
<td><a
href="https://developers.google.com/earth-engine/datasets/catalog/MODIS_061_MYD11A1#description">MODIS
daily land surface temperature</a></td>
<td>python/src/modis_lst.py</td>
<td>Mean daily LST for summer months (June-August) from the last 10
years (2012-2022) averaged within prison boundaries.</td>
<td>Caitlin</td>
<td></td>
<td></td>
<td>X</td>
</tr>
<tr class="odd">
<td>Canopy cover</td>
<td><a
href="https://developers.google.com/earth-engine/datasets/catalog/USGS_NLCD_RELEASES_2016_REL">USGS
National Land Cover Database</a></td>
<td>python/src/NLCD_canopy_cover.py</td>
<td>Average percent canopy cover within prison boundaries + 1km
buffer.</td>
<td>Caitlin</td>
<td></td>
<td></td>
<td>X</td>
</tr>
<tr class="even">
<td>Wildfire risk</td>
<td><a
href="https://www.fs.usda.gov/rds/archive/catalog/RDS-2015-0047-3">Wildfire
Hazard Potential for the United States</a></td>
<td>R/src/getWildfireRisk.R</td>
<td>Mean wildfire hazard potential within prison boundary + 1km
buffer</td>
<td>Devin</td>
<td></td>
<td></td>
<td>X</td>
</tr>
<tr class="odd">
<td>Flood risk</td>
<td><a
href="https://www.fema.gov/flood-maps/national-flood-hazard-layer">FEMA
National Flood Hazard Layer</a></td>
<td>R/src/getFloodRisk.R</td>
<td>Percentage of each prison boundary + 1km buffer that is covered by a
high risk flood zone (Zones A and Z; at least a one percent chance of
flooding annually)</td>
<td>Caitlin</td>
<td></td>
<td></td>
<td>X</td>
</tr>
<tr class="even">
<td>Ozone</td>
<td><a
href="https://sedac.ciesin.columbia.edu/data/set/aqdh-o3-concentrations-contiguous-us-1-km-2000-2016">SEDACAnnual
O3 Concentrations for CONUS</a></td>
<td>R/src/getOzone.R</td>
<td>Average annual ozone levels for 2015 and 2016 within prison
boundaries + 5km buffer</td>
<td>Caitlin</td>
<td></td>
<td>X</td>
<td></td>
</tr>
<tr class="odd">
<td>PM 2.5</td>
<td><a
href="https://sedac.ciesin.columbia.edu/data/set/aqdh-pm2-5-concentrations-contiguous-us-1-km-2000-2016">SEDACAnnual
PM2.5Concentrations for CONUS</a></td>
<td>R/src/getPM25.R</td>
<td>Average annual PM2.5 levels for 2015 and 2016 within prison
boundaries + 5km buffer</td>
<td>Caitlin</td>
<td></td>
<td>X</td>
<td></td>
</tr>
<tr class="even">
<td>Traffic volume and proximity</td>
<td><a
href="https://www.fhwa.dot.gov/policyinformation/hpms/shapefiles.cfm">FHA’s
Annual Average Daily Traffic</a></td>
<td></td>
<td>Count of vehicles (AADT, avg. annual daily traffic) at major roads
within 500 meters, divided by distance in meters (EJ Screen)</td>
<td>Caitlin</td>
<td></td>
<td></td>
<td>X</td>
</tr>
<tr class="odd">
<td>Pesticide use</td>
<td><p><a
href="https://sedac.ciesin.columbia.edu/data/set/ferman-v1-pest-chemgrids-v1-01">SEDACGlobal
Pesticide Grids</a></p>
<p><a
href="https://oehha.ca.gov/media/downloads/calenviroscreen/report/calenviroscreen40reportf2021.pdf#page=84">CalEnviroScreen
Table of volatile pesticides.</a></p></td>
<td><p>R/src/calcPesticides.R</p>
<p>Files:</p>
<p>data/processed/pesticide_sedac,</p>
<p>pesticide_sedac_2020.tif</p></td>
<td>The total harmful pesticide application from 2020 in kg/ha*yr
averaged over prison boundaries + 1km buffer</td>
<td>Devin</td>
<td></td>
<td>X</td>
<td></td>
</tr>
<tr class="even">
<td>Superfund/NPL proximity</td>
<td><a
href="https://cumulis.epa.gov/supercpad/cursites/srchrslt.cfm?start=1">EPA</a></td>
<td><p>R/src/getNPL.R</p>
<p>note: sites geocoded in ArcGIS Pro</p></td>
<td><p>Count of proposed and listed NPL facilities within 5km (or
nearest one beyond 5km) each divided by the distance in km</p>
<p>(see CA EnviroScreen for weighting by site type: <a
href="https://oehha.ca.gov/media/downloads/calenviroscreen/report/calenviroscreen40reportf2021.pdf#page=108"
class="uri">https://oehha.ca.gov/media/downloads/calenviroscreen/report/calenviroscreen40reportf2021.pdf#page=108</a>)</p></td>
<td>Devin</td>
<td></td>
<td>X</td>
<td></td>
</tr>
<tr class="odd">
<td>Risk Management Plan Facilities</td>
<td><a
href="https://hifld-geoplatform.opendata.arcgis.com/datasets/geoplatform::epa-emergency-response-er-risk-management-plan-rmp-facilities/explore?location=29.842034%2C-113.806709%2C3.92">HIFLD
EPA ER Risk Management Plan Facilities</a></td>
<td>R/src/getRMP.R</td>
<td><p>Count of Risk Management Plan (potential chemical accident
management plan) facilities within 5km (or nearest one beyond 5km) each
divided by the distance in km.</p>
<p>Modeled after EJ Screen methods (pg. 21): <a
href="https://www.epa.gov/sites/default/files/2021-04/documents/ejscreen_technical_document.pdf"
class="uri">https://www.epa.gov/sites/default/files/2021-04/documents/ejscreen_technical_document.pdf</a></p></td>
<td>Caitlin</td>
<td></td>
<td></td>
<td>X</td>
</tr>
<tr class="even">
<td>Hazardous waste facility proximity</td>
<td>EPA FRS geospatial download (updated March 2023)</td>
<td>R/src/getHazWaste.R</td>
<td><p>Count of hazardous waste facilities within 5km of prison boundary
(or nearest beyond 5km) each divided by distance in km (models EJScreen
and CO enviroscreen methods).</p>
<p>Operating TSDFs from RCRA and reporting LQGs from the Biennial Report
(localities downloaded from the EPA: <a
href="https://www.epa.gov/frs/geospatial-data-download-service"
class="uri">https://www.epa.gov/frs/geospatial-data-download-service</a>)</p></td>
<td>Devin/Caitlin</td>
<td></td>
<td></td>
<td>X</td>
</tr>
</tbody>
</table>
