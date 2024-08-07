{\rtf1\ansi\ansicpg1252\cocoartf2761
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fswiss\fcharset0 ArialMT;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\deftab720
\pard\pardeftab720\li960\fi-960\partightenfactor0

\f0\fs20 \cf0 \expnd0\expndtw0\kerning0
Title: RandomBareGroundPoints.rtf\
Description: \kerning1\expnd0\expndtw0 Generate 10,000 random points of bare ground locations on global lands using\
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardeftab720\pardirnatural\partightenfactor0
\cf0 	              the ESRI's 10m Land Use Land Cover Dataset in google earth engine.\expnd0\expndtw0\kerning0
\
\pard\pardeftab720\li960\fi-960\partightenfactor0
\cf0 Author: Christine Albano and Melissa M. Rohde\
Last date modified: 2023 April 22\
\'97\'97\'97\'97\'97\'97\'97\'97\'97\'97\'97\'97\'97\'97\'97\'97\'97\'97\'97\'97\'97\'97\'97\'97\'97\'97\'97\'97\'97\'97\kerning1\expnd0\expndtw0 \
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardeftab720\pardirnatural\partightenfactor0
\cf0 \
Map.setOptions('Satellite');\
\
// STEP 1. Define northern and southern hemispheres.\
\
// northern hemisphere box\
var nhem = ee.Geometry.Polygon(\
        [[[-126.87912652862657, 55.18891359652169],\
          [-126.87912652862657, 0],\
          [123.08181097137344, 0],\
          [123.08181097137344, 55.18891359652169]]], null, false);\
\
// southern hemisphere box\
var shem =  ee.Geometry.Polygon(\
        [[[-82.93381402862656, 0],\
          [-82.93381402862656, -55.16881919707512],\
          [153.31618597137344, -55.16881919707512],\
          [153.31618597137344, 0]]], null, false);\
\
\
// STEP 2. Load ESRI 10m Annual Land Use Land Cover(2017-2022)\
// Source: https://planetarycomputer.microsoft.com/dataset/io-lulc-9-class\
// Source: https://gee-community-catalog.org/projects/S2TSLULC/\
//  [b1]: 1-Water,2-Trees,4-Flooded Vegetation,5-Crops,6-Scrub/Shrub,7-Built Area,8-Bare Ground,9-Snow/Ice,10-Clouds, 11-Rangeland\
\
var esri_lulc10= ee.ImageCollection('projects/sat-io/open-datasets/landcover/ESRI_Global-LULC_10m_TS')\
                    .filterDate('2017-01-01','2020-12-31') // Filter dates for study period.\
                    .mosaic()\
\
// Extract the bare ground class.\
var bare = esri_lulc10.updateMask(esri_lulc10.eq(8)) \
Map.addLayer(bare,\{\},'bare ground')\
\
\
\
\
//STEP 3. Generate Random Points\
//Northern Hemisphere Random Barren points\
var randomPoints_nhem = bare.stratifiedSample(\{\
  numPoints: 5000, \
  seed: 0,\
  region:nhem,\
  projection: 'EPSG:4326',\
  scale: 30,\
  dropNulls: true,\
  geometries: true\
\});\
\
var randomPoints_shem = bare.stratifiedSample(\{\
  numPoints: 5000, \
  seed: 0,\
  region:shem,\
  projection: 'EPSG:4326',\
  scale: 30,\
  dropNulls: true,\
  geometries: true\
\});\
\
\
\
// STEP 4. Export Random Points to Google Drive, and \
// manually add class, gde_cert, gde_descr, gde_source, and gde_type fields to match other training data\
\
Export.table.toDrive(\{\
  collection: randomPoints_nhem,\
  description:'random_barren_nhem',\
  fileFormat: 'CSV'\
\});\
\
Export.table.toDrive(\{\
  collection: randomPoints_shem,\
  description:'random_barren_shem',\
  fileFormat: 'CSV'\
\});\
}