{\rtf1\ansi\ansicpg1252\cocoartf2761
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fswiss\fcharset0 ArialMT;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\deftab720
\pard\pardeftab720\li960\fi-960\partightenfactor0

\f0\fs20 \cf0 \expnd0\expndtw0\kerning0
Title: DTG_Images.rtf\
Description: Mask out surface water features from Fan et al. 2017 annual \
	mean water table depth data using google earth engine.\
Authors: Christine Albano and Melissa M. Rohde\
Last date modified: 2023 April 22\
\'97\'97\'97\'97\'97\'97\'97\'97\'97\'97\'97\'97\'97\'97\'97\'97\'97\'97\'97\'97\'97\'97\'97\'97\'97\'97\'97\'97\'97\'97\kerning1\expnd0\expndtw0 \
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardeftab720\pardirnatural\partightenfactor0
\cf0 \
/////////////////////////////////////\
// Step 1. Set Inputs and Options //\
////////////////////////////////////\
\
Map.setOptions("SATELLITE")\
\
// Define globe\
var globe = ee.Geometry.Polygon(\
      [[-176.12888854244886,-76.07716187469589],\
      [183.16798645755114,-76.07716187469589],\
      [183.16798645755114,84.58398896944963],\
      [-176.12888854244886,84.58398896944963],\
      [-176.12888854244886,-76.07716187469589]],\
      null, false );\
\
///////////////////////////////////////\
// Step 2. Load and smooth DTG Data //\
//////////////////////////////////////\
\
// Step 2.1 Load DTG data by continent\
    // Africa\
    var AfDTG = ee.Image('projects/ee-global-gde-map/assets/Fan_et_al_2017/DTG_Africa');\
    \
    // Oceania\
    var OcDTG = ee.Image('projects/ee-global-gde-map/assets/Fan_et_al_2017/DTG_Oceania');\
    \
    // North America\
    var NADTG = ee.Image('projects/ee-global-gde-map/assets/Fan_et_al_2017/DTG_NorthAmerica');\
    \
    // South America\
    var SADTG = ee.Image('projects/ee-global-gde-map/assets/Fan_et_al_2017/DTG_SouthAmerica');\
    \
    // Eurasia\
    var EADTG = ee.Image('projects/ee-global-gde-map/assets/Fan_et_al_2017/DTG_Eurasia');\
    \
    print(AfDTG.projection().nominalScale()) // Check scale for export. Original scale of data is 926 m\
\
// Step 2.2. Mosaic continental data into single image to clean up masked pixels in the DTG images (especially along rivers and water bodies). \
// Resample to smooth the data and fill in gaps.\
var DTG = ee.ImageCollection([\
  AfDTG.resample(),\
  EADTG.resample(),\
  OcDTG.resample(),\
  SADTG.resample(),\
  NADTG.resample()\
]).mosaic()\
Map.addLayer(DTG,\{bands:['b1'],min: -200, max: 0\},"DTG")\
\
\
///////////////////////////////////////////////////////////\
// Step 3. Mask out surface water features from DTW data //\
///////////////////////////////////////////////////////////\
\
// Step 3.1. Load Land cover data to identify water\
\
// ESRI 10m Annual Land Use Land Cover(2017-2022)\
// Source: https://planetarycomputer.microsoft.com/dataset/io-lulc-9-class\
// Source: https://gee-community-catalog.org/projects/S2TSLULC/\
//  [b1]: 1-Water,2-Trees,4-Flooded Vegetation,5-Crops,6-Scrub/Shrub,7-Built Area,8-Bare Ground,9-Snow/Ice,10-Clouds, 11-Rangeland\
\
var esri_lulc10= ee.ImageCollection('projects/sat-io/open-datasets/landcover/ESRI_Global-LULC_10m_TS')\
                    .filterDate('2017-01-01','2020-12-31') // Filter Dates to study period.\
                    .mosaic()\
\
// Extract the water class.\
var water = esri_lulc10.eq(1) \
Map.addLayer(water,\{\},'water')\
\
\
// Step 3.2. Create water mask and make water values = 0\
var SW_mask= esri_lulc10.updateMask(water).multiply(0)\
Map.addLayer(SW_mask,\{\},'SW_mask')\
\
// Masked DTG pixels colocated with water mask are set to 0\
var DTG_SW = DTG.unmask(SW_mask)\
print(DTG_SW) \
Map.addLayer(DTG_SW,\{bands:['b1'],min: -200, max: 0\},"DTG_SW")\
\
// Step 3.3. Smooth the data to interpolate to fill in holes with missing data\
var DTG_smooth_SW = DTG_SW.focal_mean(1.5, 'square', 'pixels')\
Map.addLayer(DTG_smooth_SW,\{bands:['b1'],min: -200, max: 0\},"DTG_Smooth_SW")\
\
// Step 3.4. Assign remaining masked values DTW=0 \
var DTG_smooth_SW0 = DTG_smooth_SW.unmask(0)\
Map.addLayer(DTG_smooth_SW0,\{bands:['b1'],min: -200, max: 0\},"DTG_Smooth_SW0")\
\
\
////////////////////////////////\
// Step 4. Export as an asset //\
////////////////////////////////\
Export.image.toAsset(\{\
  image: DTG_smooth_SW0,\
  description: 'GlobalDTG_asset',\
  assetId: 'GlobalDTG',\
  scale: 927.6586906217893,\
  region: globe,\
  maxPixels: 1E10,\
\});\
\
Export.image.toDrive(\{\
  image: DTG_smooth_SW0,\
  description: 'GlobalDTG_drive',\
  scale: 927.6586906217893,\
  region: globe,\
  maxPixels: 1E10,\
\});}