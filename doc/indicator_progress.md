Indicator Progress Tracker
================

<table style="width:99%;">
<colgroup>
<col style="width: 9%" />
<col style="width: 14%" />
<col style="width: 6%" />
<col style="width: 58%" />
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
<td></td>
<td></td>
<td></td>
<td>Caitlin</td>
<td></td>
<td></td>
<td>X</td>
</tr>
<tr class="odd">
<td>Canopy cover</td>
<td></td>
<td></td>
<td></td>
<td>Caitlin</td>
<td></td>
<td></td>
<td>X</td>
</tr>
<tr class="even">
<td>Wildfire risk</td>
<td>USDA/USFS (CO Enviroscreen)</td>
<td>wildfire_risk.R</td>
<td>Mean wildfire hazard potential within prison boundary + 1km
buffer</td>
<td>Devin</td>
<td></td>
<td>X</td>
<td>X</td>
</tr>
<tr class="odd">
<td>Flood risk</td>
<td>FEMA</td>
<td></td>
<td>Percentage of each prison boundary + 1km buffer where there is at
least a one percent chance of flooding annually</td>
<td>Caitlin</td>
<td></td>
<td>X</td>
<td></td>
</tr>
<tr class="even">
<td>Ozone</td>
<td></td>
<td></td>
<td></td>
<td>Caitlin</td>
<td></td>
<td>X</td>
<td></td>
</tr>
<tr class="odd">
<td>PM 2.5</td>
<td></td>
<td></td>
<td></td>
<td>Caitlin</td>
<td></td>
<td>X</td>
<td></td>
</tr>
<tr class="even">
<td>Traffic volume and proximity</td>
<td></td>
<td></td>
<td>Count of vehicles (AADT, avg. annual daily traffic) at major roads
within 500 meters, divided by distance in meters (EJ Screen)</td>
<td>Caitlin</td>
<td>X</td>
<td></td>
<td></td>
</tr>
<tr class="odd">
<td>Pesticide use</td>
<td>SEDAC(PEST-CHEMGRIDS v1.01), CalEnviroScreen Table of volatile
pesticides.</td>
<td><p>calcPesticides()</p>
<p>Files:</p>
<p>data/processed/pesticide_sedac,</p>
<p>pesticide_sedac_2020.tif</p></td>
<td>Total pounds of 132 selected active pesticide ingredients (filtered
for hazard and volatility) used in production-agriculture per square
mile, averaged over three years (2017 to 2019). (CA method: <a
href="https://oehha.ca.gov/media/downloads/calenviroscreen/report/calenviroscreen40reportf2021.pdf#page=79"
class="uri">https://oehha.ca.gov/media/downloads/calenviroscreen/report/calenviroscreen40reportf2021.pdf#page=79</a>)</td>
<td>Devin</td>
<td></td>
<td>X</td>
<td></td>
</tr>
<tr class="even">
<td>Superfund and NPL proximity</td>
<td>EPA (Query: <a
href="https://cumulis.epa.gov/supercpad/cursites/srchsites.cfm"
class="uri">https://cumulis.epa.gov/supercpad/cursites/srchsites.cfm</a>)</td>
<td><p>Files:</p>
<p>superfund_npl_active_2023ver.csv</p>
<p>Fun:</p>
<p>ArcGIS Pro geocoding</p>
<p>buffer_calculatoin()</p>
<p>power_weight_calculation()</p></td>
<td>Sum of listed and proposed NPL sites weighted by distance to prison
boundary and type of NPL site (see CA EnviroScreen for weighting by site
type: <a
href="https://oehha.ca.gov/media/downloads/calenviroscreen/report/calenviroscreen40reportf2021.pdf#page=108"
class="uri">https://oehha.ca.gov/media/downloads/calenviroscreen/report/calenviroscreen40reportf2021.pdf#page=108</a>)</td>
<td>Devin</td>
<td></td>
<td>X</td>
<td></td>
</tr>
<tr class="odd">
<td>Nuclear power, non-renewable plant proximity</td>
<td>World Resources Institute</td>
<td><p>File:</p>
<p>global_power_plant_database.csv</p>
<p>Fun:</p>
<p>buffer_calculation()</p></td>
<td>Similar distance weighted sum as Superfund site method</td>
<td>Devin</td>
<td></td>
<td>X</td>
<td></td>
</tr>
<tr class="even">
<td>Hazardous waste facility proximity</td>
<td>EPA FRS geospatial download (updated March 2023)</td>
<td></td>
<td><p>Count of hazardous waste facilities within 5km of prison boundary
(or nearest beyond 5km) each divided by distance in km (models EJScreen
and CO enviroscreen methods).</p>
<p>Operating TSDFs from RCRA and reporting LQGs from the Biennial Report
(localities downloaded from the EPA: <a
href="https://www.epa.gov/frs/geospatial-data-download-service"
class="uri">https://www.epa.gov/frs/geospatial-data-download-service</a>)</p></td>
<td>Devin/Caitlin</td>
<td>X</td>
<td></td>
<td></td>
</tr>
<tr class="odd">
<td>Wastewater discharge indicator</td>
<td>EJ Screen</td>
<td></td>
<td>Estimated toxic chemical concentrations in stream segments within
500 meters of prison boundary, divided by distance in kilometers (km) in
2019</td>
<td>Devin</td>
<td></td>
<td></td>
<td></td>
</tr>
</tbody>
</table>
