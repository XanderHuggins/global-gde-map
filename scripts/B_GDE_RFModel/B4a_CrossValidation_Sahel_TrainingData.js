{\rtf1\ansi\ansicpg1252\cocoartf2709
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardirnatural\partightenfactor0

\f0\fs24 \cf0 ////////////////////////////////////////////////////////////////////////////////////////////////////\
// Title: 6_CrossValidation_Sahel_TrainingData\
// Authors: Christine Albano and Melissa M. Rohde\
// Description: Cross validation test using GDE data from the Sahel to verify the global GDE map.  This script generates training points from the Sahel.\
// Last Date Modified: April 23, 2023\
////////////////////////////////////////////////////////////////////////////////////////////////////\
\
\
// STEP 1. Generate Random Non-GDE points in the Sahel \
\
// Load ESRI 10m Annual Land Use Land Cover(2017-2022)\
// Source: https://planetarycomputer.microsoft.com/dataset/io-lulc-9-class\
// Source: https://gee-community-catalog.org/projects/S2TSLULC/\
//  [b1]: 1-Water,2-Trees,4-Flooded Vegetation,5-Crops,6-Scrub/Shrub,7-Built Area,8-Bare Ground,9-Snow/Ice,10-Clouds, 11-Rangeland\
\
var esri_lulc10= ee.ImageCollection('projects/sat-io/open-datasets/landcover/ESRI_Global-LULC_10m_TS')\
                    .filterDate('2017-01-01','2020-12-31') // Composite of study period.\
                    .mosaic();\
\
var barren_sahel = esri_lulc10.updateMask(esri_lulc10.eq(8)).clip(Sahel)\
\
\
//print(barren_sahel.projection(),'barren_sahel') //check projection for stratifiedSample\
\
var SahelNonGDEpts = barren_sahel.stratifiedSample(\{\
  numPoints: 5000, \
  seed: 0,\
  projection: 'EPSG:4326',\
  scale: 30,\
  dropNulls: true,\
  geometries: true\
\});\
\
Map.addLayer(SahelNonGDEpts,\{palette:['red']\},'SahelNonGDEpts')\
\
\
// STEP 2. Generate Random GDE points in the Sahel\
//Load GDE data\
var SahelGDE = gde_lines.merge(gde_point)\
               .filterBounds(Sahel)\
               .geometry()\
               .buffer(50)\
\
// Generate 5000 random GDE points\
var SahelGDEpts = ee.FeatureCollection.randomPoints(\
                      \{region: SahelGDE, points: 5000, seed: 0, maxError: 1\});\
Map.addLayer(SahelGDE, \{\}, 'SahelGDE')\
Map.addLayer(SahelGDEpts, \{palette:['blue']\}, 'SahelGDEpts')\
\
\
\
// STEP 3. Export Sahel Points\
\
Export.table.toAsset(\{\
  collection:SahelGDEpts,\
  description:'SahelGDEpts',\
  assetId:"SahelGDEpts"\
\});\
\
Export.table.toAsset(\{\
  collection:SahelNonGDEpts,\
  description:'SahelNonGDEpts',\
  assetId:"SahelNonGDEpts"\
\});\
\
\
}