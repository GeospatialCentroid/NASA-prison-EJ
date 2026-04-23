Indicator Metatdata
================

<table style="width:99%;">
<colgroup>
<col style="width: 8%" />
<col style="width: 32%" />
<col style="width: 5%" />
<col style="width: 6%" />
<col style="width: 31%" />
<col style="width: 5%" />
<col style="width: 6%" />
<col style="width: 3%" />
</colgroup>
<tbody>
<tr>
<td>Indicator</td>
<td>Dataset used</td>
<td>Function / file name</td>
<td>Processing script (if applicable)</td>
<td>Indicator Description</td>
<td>Time frame / last updated</td>
<td>Spatial resolution (if raster)</td>
<td>Phase 2 Updated</td>
</tr>
<tr>
<td>Heat index</td>
<td>Landsat 8/9 Collection 2 Level-2 Surface Temperature (ST_B10)</td>
<td>python/calc_lst_landsat.py</td>
<td></td>
<td>Mean LST for summer months (June-August) from the last three years
(2022-2025) averaged within prison boundaries.</td>
<td>2022 - 2025</td>
<td>30 m</td>
<td>Yes</td>
</tr>
<tr>
<td>Canopy cover</td>
<td><a
href="https://developers.google.com/earth-engine/datasets/catalog/USGS_NLCD_RELEASES_2023_REL_TCC_v2023-5">USGS
National Land Cover Database</a></td>
<td>python/calc_canopy_cover.py</td>
<td></td>
<td>Average percent canopy cover within prison boundaries + 1km
buffer.</td>
<td>2023</td>
<td>30 m</td>
<td>Yes</td>
</tr>
<tr>
<td>Wildfire risk</td>
<td><a
href="https://www.fs.usda.gov/rds/archive/catalog/RDS-2015-0047-4">Wildfire
Hazard Potential for the United States</a></td>
<td>calc_wildfire_risk.R</td>
<td></td>
<td>Mean wildfire hazard potential within prison boundary + 1km
buffer</td>
<td>2024</td>
<td>270 m</td>
<td>Yes</td>
</tr>
<tr>
<td>Flood risk</td>
<td><a
href="https://www.fema.gov/flood-maps/national-flood-hazard-layer">FEMA
National Flood Hazard Layer</a></td>
<td>calc_flood_risk.R</td>
<td></td>
<td>Percentage of each prison boundary + 1km buffer that is covered by a
high risk flood zone (Zones A and Z; at least a one percent chance of
flooding annually)</td>
<td>2026</td>
<td></td>
<td>Yes</td>
</tr>
<tr>
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
<td></td>
</tr>
<tr>
<td>PM 2.5</td>
<td><a href="https://sites.wustl.edu/acag/surface-pm2-5/">Wash U
St. Louis - van Donkelaar et al. 2024. North American Regional
Estimates</a></td>
<td>calc_pm25.R</td>
<td>process_data/process_pm25.R</td>
<td>Average annual PM2.5 levels within prison boundaries + 1km
buffer</td>
<td>2021-2023</td>
<td>1 km</td>
<td>Yes</td>
</tr>
<tr>
<td>Traffic volume and proximity</td>
<td><a
href="https://www.fhwa.dot.gov/policyihttps://geodata.bts.gov/datasets/483bd180fe814872b82a66dbf65e25f0nformation/hpms/shapefiles.cfm">FHA’s
Annual Average Daily Traffic</a></td>
<td>calc_traffic_proximity.R</td>
<td>process_data/process_traffic.R</td>
<td>Count of vehicles (AADT, avg. annual daily traffic) at major roads
within 500 meters, divided by distance in meters</td>
<td>2023</td>
<td></td>
<td>Yes</td>
</tr>
<tr>
<td>Pesticide use</td>
<td><a href="https://doi.org/10.6084/m9.figshare.25854769.v2">Global
PEST-CHEMGRIDS V2.01 Beta</a> Maggie and Tang 2024.</td>
<td>calc_pesticides.R</td>
<td></td>
<td>The total pesticide application from 2018 in kg/ha*yr averaged over
prison boundaries + 1km buffer.</td>
<td>2018</td>
<td>~ 10 km (5 arc-minute)</td>
<td>Yes</td>
</tr>
<tr>
<td>Superfund/NPL proximity</td>
<td><a
href="https://cumulis.epa.gov/supercpad/CurSites/srchsites.cfm">EPA</a>
(click ‘View a list of all NPL and SAA sites’ then ‘Download Excel
file’)</td>
<td>calc_npl_proximity.R</td>
<td>process_data/process_npl.R</td>
<td>Count of proposed and listed NPL facilities within 5km (or nearest
one beyond 5km) each divided by the distance in km</td>
<td>February 2026</td>
<td></td>
<td>Yes</td>
</tr>
<tr>
<td>Risk Management Plan facility proximity</td>
<td><a
href="https://www.data-liberation-project.org/datasets/epa-risk-management-program-database/">The
Data Liberation Project - EPA Risk Management Program Database</a></td>
<td>calc_rmp_proximity.R</td>
<td></td>
<td><p>Count of Risk Management Plan (potential chemical accident
management plan) facilities within 5km (or nearest one beyond 5km) each
divided by the distance in km.</p>
<p>Modeled after EJ Screen methods (pg. 21): <a
href="https://www.epa.gov/sites/default/files/2021-04/documents/ejscreen_technical_document.pdf"
class="uri">https://www.epa.gov/sites/default/files/2021-04/documents/ejscreen_technical_document.pdf</a></p></td>
<td>January 2026</td>
<td></td>
<td>Yes</td>
</tr>
<tr>
<td>Hazardous waste facility proximity</td>
<td><a
href="https://www.epa.gov/frs/geospatial-data-download-service">EPA FRS
geospatial download</a> (Downloaded the National and State ALL FRS
single CSV file)</td>
<td>calc_haz_waste_proximity.R</td>
<td>process_data/process_haz_waste/R</td>
<td>Count of hazardous waste facilities within 5km of prison boundary
(or nearest beyond 5km) each divided by distance in km</td>
<td>January 2025</td>
<td></td>
<td>Yes</td>
</tr>
</tbody>
</table>
