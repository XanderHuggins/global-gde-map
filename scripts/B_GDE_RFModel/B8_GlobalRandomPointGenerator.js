{\rtf1\ansi\ansicpg1252\cocoartf2709
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardirnatural\partightenfactor0

\f0\fs24 \cf0 ////////////////////////////////////////////////////////////////////////////////////////////////////\
// Title: Derive random points across analysis extent\
// Authors: Christine Albano and Melissa M. Rohde\
// Description: Generate 125,000 random points, retaining only \
// those that fall within the analysis mask - n~33,000 global points\
// Last Date Modified: April 25, 2023\
////////////////////////////////////////////////////////////////////////////////////////////////////\
\
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////\
//STEP 1. Define hemispheric extents for clipping purposes limits are intended to reduce sampling area to boundaries \
//        of analysis extent. Random sampling limited to regions smaller than hemisphere.\
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////\
\
// Northern hemisphere box\
      \
var nhem = ee.Geometry.Polygon(\
        [[[-128.87912652862657, 55.18891359652169],\
          [-128.87912652862657, 0],\
          [125.08181097137344, 0],\
          [125.08181097137344, 55.18891359652169]]], null, false);\
\
// Southern hemisphere box\
var shem =  ee.Geometry.Polygon(\
        [[[-82.93381402862656, 0],\
          [-82.93381402862656, -55.16881919707512],\
          [153.31618597137344, -55.16881919707512],\
          [153.31618597137344, 0]]], null, false);\
\
Map.addLayer(shem,\{\},'S.Hemisphere')  \
Map.addLayer(nhem,\{\},'N.Hemisphere')  \
\
/////////////////////////////////////////////////////////////////\
// Step 2. Define Masks //\
/////////////////////////////////////////////////////////////////\
\
// Step 2.1. Load Masking Datasets\
\
// A. Land Cover - ESRI 10m Annual Land Use Land Cover(2017-2022)\
// Source: https://planetarycomputer.microsoft.com/dataset/io-lulc-9-class\
// Source: https://gee-community-catalog.org/projects/S2TSLULC/\
//[b1]: 1-Water,2-Trees,4-Flooded Vegetation,5-Crops,6-Scrub/Shrub,7-Built Area,8-Bare Ground,9-Snow/Ice,10-Clouds,11-Rangeland\
\
var esri_lulc10= ee.ImageCollection('projects/sat-io/open-datasets/landcover/ESRI_Global-LULC_10m_TS')\
                    .filterDate('2017-01-01','2020-12-31') // Filter dates for study period.\
                    .mosaic();\
\
    var urb = esri_lulc10.neq(7); // built\
    var ag = esri_lulc10.neq(5); // crops\
    var ice = esri_lulc10.neq(9); // snow/ice\
    var cloud = esri_lulc10.neq(10); // clouds    \
\
\
// B. Depth to groundwater (DTG)\
// Source: Fan et al. 2017 -- smoothed/pre-processed using "1_DTG_Smoothing" google earth engine code.\
var DTG = ee.Image('projects/ee-global-gde-map/assets/GlobalDTG') \
          .resample('bilinear').rename('DTG')\
var DTG_mask = DTG.gte(-30) // Mask out DTG depths greater than or equal to 30 meters.\
Map.addLayer(DTG.updateMask(DTG_mask), \{min: -200.0, max: 0, palette:  ['#EFE7E1', '#003300']\}, 'DTG', false)\
\
// C. Drylands\
// Source: Koppen-Geiger regions (Beck et al. 2018)\
var KG_regions = ee.Image('projects/ee-global-gde-map/assets/Beck_KG_V1_present_0p0083');\
//create a mask to arid and temperate dry summer regions\
var KG_mask2 = KG_regions.lte(10).and(KG_regions.gt(3))//change 10 to 7 to include only arid regions\
\
\
//2.2 Create Masked Extent\
\
    var studyextN = esri_lulc10.updateMask(urb).updateMask(ag).updateMask(ice).updateMask(cloud).updateMask(KG_mask2).updateMask(DTG_mask).clip(nhem)\
    var studyextS = esri_lulc10.updateMask(urb).updateMask(ag).updateMask(ice).updateMask(cloud).updateMask(KG_mask2).updateMask(DTG_mask).clip(shem)\
    Map.addLayer(studyextN,\{\},'studyextN')\
    Map.addLayer(studyextS,\{\},'studyextS')\
\
\
\
/////////////////////////////////////////////////////////////////\
// STEP 3.Generate Random Points\
/////////////////////////////////////////////////////////////////\
\
var randomPointsN = studyextN.sample(\{\
  seed: 0,\
  projection: 'EPSG:4326',\
  scale: 30,\
  numPixels: 225000,\
  dropNulls: true,\
  geometries: true\
\});\
//print('Points:',randomPointsN.first())\
\
\
var randomPointsS = studyextS.sample(\{\
  seed: 0,\
  projection: 'EPSG:4326',\
  scale: 30,\
  numPixels: 150000,\
  dropNulls: true,\
  geometries: true\
\});\
//print('Points:',randomPointsN.first())\
\
\
/////////////////////////////////////////////////////////////////\
// STEP 4. Export Random Points to Google Drive\
//////////////////////////////////////////////////////////////////\
\
Export.table.toDrive(\{\
  collection: randomPointsN,\
  description:'randomGlobalPts_validationN',\
  fileFormat: 'CSV'\
\});\
\
Export.table.toDrive(\{\
  collection: randomPointsS,\
  description:'randomGlobalPts_validationS',\
  fileFormat: 'CSV'\
\});\
}