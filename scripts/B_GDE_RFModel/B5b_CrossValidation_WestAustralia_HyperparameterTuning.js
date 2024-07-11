{\rtf1\ansi\ansicpg1252\cocoartf2709
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardirnatural\partightenfactor0

\f0\fs24 \cf0 ////////////////////////////////////////////////////////////////////////////////////////////////////\
// Title: 7_CrossValidation_WestAustralia_HyperparameterTuning\
// Authors: Melissa M. Rohde\
// Description: Tune parameters in random forest for West Australia cross validation test\
// to retrieve optimal parameters to achieve highest accuracy\
// Last Date Modified: April 23, 2023\
////////////////////////////////////////////////////////////////////////////////////////////////////\
\
\
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
// Define northern hemisphere\
var nhem = ee.Geometry.Polygon(\
        [[[-180, 60], [-180, 0], [0, 0], [180, 0], [180, 60], [0, 60]]], \
        null, false);\
\
// Define southern hemisphere\
var shem = ee.Geometry.Polygon(\
        [[[-180, 0], [-180, -60], [0, -60], [180, -60], [180, 0], [0, 0]]], \
        null, false);\
\
/////////////////////////////////////////////////////////////////\
// Step 2. Compile predictor variables for the predictor image //\
/////////////////////////////////////////////////////////////////\
\
// Step 2.1. Load Datasets\
\
// A. Land Cover\
// ESRI 10m Annual Land Use Land Cover(2017-2022)\
// Source: https://planetarycomputer.microsoft.com/dataset/io-lulc-9-class\
// Source: https://gee-community-catalog.org/projects/S2TSLULC/\
//  [b1]: 1-Water,2-Trees,4-Flooded Vegetation,5-Crops,6-Scrub/Shrub,7-Built Area,8-Bare Ground,9-Snow/Ice,10-Clouds, 11-Rangeland\
\
var esri_lulc10= ee.ImageCollection('projects/sat-io/open-datasets/landcover/ESRI_Global-LULC_10m_TS')\
                    .filterDate('2017-01-01','2020-12-31') // Composite of study period.\
                    .mosaic();\
\
    var urb = esri_lulc10.neq(7); // built\
    var ag = esri_lulc10.neq(5); // crops\
\
    // Landcover to mask out oceans\
    var dlc_100m = ee.Image("COPERNICUS/Landcover/100m/Proba-V-C3/Global/2019").select('discrete_classification');\
    var ocean_dlc = dlc_100m.neq(200) //oceans\
\
// B. Depth to groundwater (DTG)\
// Source: Fan et al. 2017 -- smoothed/pre-processed using "DTG_Smoothing" google earth engine code.\
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
// D. Compound Topographic Index (CTI)\
    // Source: https://catalogue.ceh.ac.uk/documents/6b0c4358-2bf3-4924-aa8f-793d468b92be\
    var CTI = ee.Image('projects/ee-global-gde-map/assets/TopConvIndex_Global_KGclims').resample('bilinear').rename('CTI');\
    //print("CTI",CTI)\
    Map.addLayer(CTI, \{min: -1,max: 13,palette: ['0b1eff', '4be450', 'fffca4', 'ffa011', 'ff0000'],\}, 'CTI', false)\
\
\
// E. Climate data - annual precipitation (pr), potential (pet) and actual evapotranspiration (ETa) data, and ET/P ratios\
      var terraclimate = ee.ImageCollection('IDAHO_EPSCOR/TERRACLIMATE').select('pr', 'pet');\
      var years = ee.List.sequence(2003, 2016)//years ETa data are available\
      \
      // Convert monthly pet and pr to annual sums \
      function annualSums(y)\{\
        return terraclimate\
          .filter(ee.Filter.calendarRange(y, y, 'year'))\
          .select(['pr', 'pet'])\
          .reduce(ee.Reducer.sum())\
          .set(\{'system:time_start': ee.Date.fromYMD(y, 1, 1), \
                'year': y\})\}\
      var byAnnual = ee.ImageCollection(years.map(annualSums))\
      \
      // Import ETa data\
      var ETa = ee.ImageCollection('CAS/IGSNRR/PML/V2_v017').select("Ec")  \
      \
      function annualETas(y)\{\
        return ETa\
          .filter(ee.Filter.calendarRange(y, y, 'year'))\
          .reduce(ee.Reducer.sum())\
          .set(\{'system:time_start': ee.Date.fromYMD(y, 1, 1), \
                'year': y\})\}\
      var byETaAnnual = ee.ImageCollection(years.map(annualETas))\
      \
      // Calculate multiyear averages\
      var climos = byAnnual.mean().resample('bilinear').reproject('EPSG:4326',null, 500)\
      var ETann = byETaAnnual.mean().reproject('EPSG:4326',null,500)\
      \
      //Calculate ETa:P\
      var etaP = ETann.divide(climos.select('pr_sum')).resample('bilinear').rename('ETaP')\
      //Map.addLayer(etaP,\{min: 0, max: 1, palette:  ['#EFE7E1', '#003300']\},'ETaP)\
\
\
// F. Other optional predictor varibale: Multi-scaled topographic position index (TPI) derived from elevation \
    // Source: Theobald et al. 2015\
          var mTPI = ee.Image("CSP/ERGo/1_0/Global/SRTM_mTPI").resample('bilinear').rename("mTPI");//multi-scale topographic position index\
          Map.addLayer(mTPI,\{min: -200.0,max: 200.0,palette: ['0b1eff', '4be450', 'fffca4', 'ffa011', 'ff0000'],\}, 'mTPI', false)\
\
// Step 2.2. Process Landsat Data\
//Calculate metrics and get them into a single image with predictor variables as bands\
\
// Step 2.2.1 Select dates\
      var year_start = 2015;\
      var year_end = 2020;  // Inclusive\
      var YEAR_LIST = ee.List.sequence(year_start, year_end);\
      var YEAR_RANGE = ee.Filter.calendarRange(year_start, year_end, 'year');\
      \
      // Select day of year range for each hemisphere to compute veg metrics for each year\
      var DOY_RANGE_NHEM = ee.Filter.calendarRange(182, 273, 'day_of_year'); //July 1  - Sept 30\
      var DOY_RANGE_SHEM = ee.Filter.calendarRange(1, 90, 'day_of_year'); //Jan 1 - Mar 31\
\
\
// Step 2.2.2. Create functions to mask and AddBands\
\
// Mask Clouds\
  function maskL8sr(image) \{\
      var cloudShadowBitMask = (1 << 4);\
      var cloudsBitMask = (1 << 3);\
      var cirrusBitMask = (1 << 2);\
      var snowBitMask = (1 << 5);\
      var dilateBitMask = (1 << 1)\
      // Get the pixel QA band.\
      var qa = image.select('QA_PIXEL');\
      // All flags should be set to zero, indicating clear conditions.\
      var mask = qa.bitwiseAnd(cloudShadowBitMask).eq(0)\
                    .and(qa.bitwiseAnd(cloudsBitMask).eq(0))\
                    .and(qa.bitwiseAnd(cirrusBitMask).eq(0))\
                    .and(qa.bitwiseAnd(dilateBitMask).eq(0))\
                    .and(qa.bitwiseAnd(snowBitMask).eq(0));\
      return image.updateMask(mask);\
      \}\
      \
// Mask clouds and LST QA less than 5 degrees\
function maskL8srLST(image)\{\
  var cloudShadowBitMask = (1 << 4)\
  var cloudsBitMask = (1 << 3)\
  var cirrusBitMask = (1 << 2)\
  var snowBitMask = (1 << 5)\
  var dilateBitMask = (1 << 1)\
  // ## Get the pixel QA band.\
  var qa = image.select('QA_PIXEL')\
  var qa2 = image.select('ST_QA').multiply(0.01).subtract(273.15)\
  // ## All flags should be set to zero, indicating clear conditions.\
  var mask = qa2.lte(5).and(qa.bitwiseAnd(cloudShadowBitMask).eq(0))\
    .and(qa.bitwiseAnd(cloudsBitMask).eq(0))\
    .and(qa.bitwiseAnd(cirrusBitMask).eq(0))\
    .and(qa.bitwiseAnd(dilateBitMask).eq(0))\
    .and(qa.bitwiseAnd(snowBitMask).eq(0))\
  return image.updateMask(mask)\}\
  \
// Calculate vegetation indices  \
  \
  function NDVI(image)\{\
    return image.normalizedDifference(['SR_B5', 'SR_B4']).rename("ndvi")\}\
  \
  function NDWI1(image)\{\
    return image.normalizedDifference(['SR_B3', 'SR_B5']).rename("ndwi_water")\}\
  \
  function NDWI2(image)\{\
    return image.normalizedDifference(['SR_B5', 'SR_B6']).rename("ndwi_leaf")\}\
  \
  function MSAVI(image)\{\
    return image\
      .expression(\
        '(2 * NIR + 1 - ((((2* NIR +1)**2)-8*(NIR-RED))**0.5)) / 2', \{\
        'NIR': image.select('SR_B5'), 'RED': image.select('SR_B4')\})\
      .rename("msavi")\}\
  \
\
// Prepare Landsat Surface Reflectance data\
function landsatPrep(image)\{\
  var landsat = maskL8sr(image)\
    .select(['SR_B3', 'SR_B4', 'SR_B5', 'SR_B6'])\
    .multiply([0.0000275, 0.0000275, 0.0000275, 0.0000275])\
    .add([-0.2, -0.2, -0.2, -0.2])\
    .updateMask(KG_mask2)\
    .updateMask(urb)\
    .updateMask(ag)\
    .updateMask(ocean_dlc)\
    .updateMask(DTG_mask)\
  return landsat.addBands([NDVI(landsat), NDWI1(landsat), NDWI2(landsat), MSAVI(landsat)])\
    .set(\{'system:time_start': image.get('system:time_start')\})\}\
\
// Prepare Landsat Surface Temperature data\
function landsatLSTPrep(image)\{\
  var landsatLST = maskL8srLST(image)\
    .select(['ST_B10'])\
    .multiply([0.00341802])\
    .add([149])\
    .updateMask(KG_mask2)\
    .updateMask(ocean_dlc)\
  return landsatLST.select(['ST_B10'])\
    .addBands([TPI270(landsatLST), TPI2700(landsatLST), TPI5400(landsatLST)])\
    .set(\{'system:time_start': image.get('system:time_start')\})\}\
    \
\
 // Calculate mean late summer NDVI/NDWI by year\
  function mean_annual_nhem(year)\{\
    var date_start = ee.Date.fromYMD(year, 1, 1)\
    var ndvi_coll = ee.ImageCollection('LANDSAT/LC08/C02/T1_L2')\
      .filterDate(date_start, date_start.advance(1, 'year'))\
      .filterBounds(nhem)\
      .filter(DOY_RANGE_NHEM)\
      .filter(ee.Filter.lte('CLOUD_COVER', 20))\
      .map(landsatPrep)\
      .select(['ndvi', 'ndwi_leaf', 'ndwi_water', 'msavi'])\
    return ee.Image([ee.Image.constant(year).toFloat(), ee.Image(ndvi_coll.mean())])\
      .set('system:time_start', date_start.millis())\}\
\
 // Calculate mean late summer lst anomaly by year\
  function mean_annual_lst_nhem(year)\{\
    var date_start = ee.Date.fromYMD(year, 1, 1)\
    var ndvilst_coll = ee.ImageCollection('LANDSAT/LC08/C02/T1_L2')\
      .filterDate(date_start, date_start.advance(1, 'year'))\
      .filterBounds(nhem)\
      .filter(DOY_RANGE_NHEM)\
      .filter(ee.Filter.lte('CLOUD_COVER', 20))\
      .map(landsatLSTPrep)\
      .select(['lst_tpi5400', 'lst_tpi2700', 'lst_tpi270'])\
    return ee.Image([ee.Image.constant(year).toFloat(), ee.Image(ndvilst_coll.mean())])\
      .set('system:time_start', date_start.millis())\
      \}\
\
// Calculate growing season variability (cv) of NDVI/NDWI by year\
 function cv_annual_nhem(year)\{\
    var date_start = ee.Date.fromYMD(year, 1, 1)\
    var ndvi_coll = ee.ImageCollection('LANDSAT/LC08/C02/T1_L2')\
      .filterDate(date_start, date_start.advance(1, 'year'))\
      .filterBounds(nhem)\
      .filter(DOY_RANGE_NHEM)\
      .filter(ee.Filter.lte('CLOUD_COVER', 20))\
      .map(landsatPrep)\
      .select(['ndvi', 'ndwi_leaf', 'ndwi_water', 'msavi'])\
    var value = ee.Image(ndvi_coll.reduce(ee.Reducer.stdDev()))\
      .divide(ee.Image(ndvi_coll.mean()))\
    return ee.Image([ee.Image.constant(year).toFloat(), value])\
      .set('system:time_start', date_start.millis())\}\
\
 // Calculate mean late summer NDVI/NDWI by year\
  function mean_annual_shem(year)\{\
    var date_start = ee.Date.fromYMD(year, 1, 1)\
    var ndvi_coll = ee.ImageCollection('LANDSAT/LC08/C02/T1_L2')\
      .filterDate(date_start, date_start.advance(1, 'year'))\
      .filterBounds(shem)\
      .filter(DOY_RANGE_SHEM)\
      .filter(ee.Filter.lte('CLOUD_COVER', 20))\
      .map(landsatPrep)\
      .select(['ndvi', 'ndwi_leaf', 'ndwi_water', 'msavi'])\
    return ee.Image([ee.Image.constant(year).toFloat(), ee.Image(ndvi_coll.mean())])\
      .set('system:time_start', date_start.millis())\}\
\
 // Calculate mean late summer LST anomaly by year\
  function mean_annual_lst_shem(year)\{\
    var date_start = ee.Date.fromYMD(year, 1, 1)\
    var ndvilst_coll = ee.ImageCollection('LANDSAT/LC08/C02/T1_L2')\
      .filterDate(date_start, date_start.advance(1, 'year'))\
      .filterBounds(shem)\
      .filter(DOY_RANGE_SHEM)\
      .filter(ee.Filter.lte('CLOUD_COVER', 20))\
      .map(landsatLSTPrep)\
      .select(['lst_tpi5400', 'lst_tpi2700', 'lst_tpi270'])\
    return ee.Image([ee.Image.constant(year).toFloat(), ee.Image(ndvilst_coll.mean())])\
      .set('system:time_start', date_start.millis())\
      \}\
\
// Calculate growing seasonal variability (cv) of NDVI/NDWI by year\
 function cv_annual_shem(year)\{\
    var date_start = ee.Date.fromYMD(year, 1, 1)\
    var ndvi_coll = ee.ImageCollection('LANDSAT/LC08/C02/T1_L2')\
      .filterDate(date_start, date_start.advance(1, 'year'))\
      .filterBounds(shem)\
      .filter(DOY_RANGE_SHEM)\
      .filter(ee.Filter.lte('CLOUD_COVER', 20))\
      .map(landsatPrep)\
      .select(['ndvi', 'ndwi_leaf', 'ndwi_water', 'msavi'])\
    var value = ee.Image(ndvi_coll.reduce(ee.Reducer.stdDev()))\
      .divide(ee.Image(ndvi_coll.mean()))\
    return ee.Image([ee.Image.constant(year).toFloat(), value])\
      .set('system:time_start', date_start.millis())\}\
      \
\
// Optional: Calculate 'Topographic Positional Index' for LST based on rectangle -----//\
//get pixel LST difference from average of all pixels within x,y m\
\
function TPI5400(image)\{\
  var kernel = ee.Kernel.rectangle(5400,5400,'meters',false,1)\
  var focalmean = image.select('ST_B10').subtract(273.15).reduceNeighborhood( \{reducer: ee.Reducer.mean(),\
    kernel: kernel,\
    skipMasked: true,\
    optimization: 'boxcar'\})\
  var TPI = image.select('ST_B10').subtract(273.15)\
  .subtract(focalmean)\
  .toFloat()\
  .rename('lst_tpi5400')\
  return image.addBands(TPI)\}\
\
\
function TPI2700(image)\{\
  var kernel = ee.Kernel.rectangle(2700,2700,'meters',false,1)\
  var focalmean = image.select('ST_B10').subtract(273.15).reduceNeighborhood( \{reducer: ee.Reducer.mean(),\
    kernel: kernel,\
    skipMasked: true,\
    optimization: 'boxcar'\})\
  var TPI = image.select('ST_B10').subtract(273.15).subtract(focalmean).toFloat().rename('lst_tpi2700')\
  return image.addBands(TPI)\}\
\
\
function TPI270(image)\{\
  var kernel = ee.Kernel.rectangle(270,270,'meters',false,1)\
  var focalmean = image.select('ST_B10').subtract(273.15).reduceNeighborhood( \{reducer: ee.Reducer.mean(),\
    kernel: kernel,\
    skipMasked: true,\
    optimization: 'boxcar'\})\
  var TPI = image.select('ST_B10').subtract(273.15).subtract(focalmean).toFloat().rename('lst_tpi270')\
  return image.addBands(TPI)\}\
\
\
// STEP 2.2.3. Create predictor variables\
// Calculate mean late summer indices (NDVI/NDWI/MSAVI) and LST by year\
 var mean_annual_ndvi_collnhem = ee.ImageCollection(YEAR_LIST.map(mean_annual_nhem))\
 var mean_annual_lst_collnhem = ee.ImageCollection(YEAR_LIST.map(mean_annual_lst_nhem))\
 var mean_annual_ndvi_collshem = ee.ImageCollection(YEAR_LIST.map(mean_annual_shem))\
 var mean_annual_lst_collshem = ee.ImageCollection(YEAR_LIST.map(mean_annual_lst_shem))\
\
var mean_annual_ndvi_coll = mean_annual_ndvi_collnhem.merge(mean_annual_ndvi_collshem)\
var mean_annual_lst_coll = mean_annual_lst_collnhem.merge(mean_annual_lst_collshem)\
\
// Calculate growing season variability (coefficient of variation=StdDev/mean) of indices (NDVI/NDWI/MSAVI) by year\
var cv_annual_ndvi_collnhem = ee.ImageCollection(YEAR_LIST.map(cv_annual_nhem))\
var cv_annual_ndvi_collshem = ee.ImageCollection(YEAR_LIST.map(cv_annual_shem))\
var cv_annual_ndvi_coll = cv_annual_ndvi_collnhem.merge(cv_annual_ndvi_collshem)\
\
// Calculate AMONG year variability -- multi-year mean and cv of late summer indices (NDVI/NDWI/MSAVI) \
var   mean_vis = mean_annual_ndvi_coll\
    .select(['ndvi', 'ndwi_leaf', 'ndwi_water', 'msavi'])\
    .mean();\
    \
var cv_vis = mean_annual_ndvi_coll\
    .select(['ndvi', 'ndwi_leaf', 'ndwi_water', 'msavi'])\
    .reduce(ee.Reducer.stdDev())\
    .divide(mean_annual_ndvi_coll\
              .select(['ndvi', 'ndwi_leaf', 'ndwi_water', 'msavi'])\
              .mean())\
    .rename(['ndvi_cv', 'ndwi_leaf_cv', 'ndwi_water_cv', 'msavi_cv']);\
    \
var seas_cv_vis = cv_annual_ndvi_coll\
    .select(['ndvi_stdDev', 'ndwi_leaf_stdDev', 'ndwi_water_stdDev', 'msavi_stdDev'])\
    .mean()\
    .rename(['ndvi_seas_cv', 'ndwi_leaf_seas_cv', 'ndwi_water_seas_cv', 'msavi_seas_cv']);\
\
// OPTIONAL: Get multi-scaled TPI\
var mean_lst_tpi = mean_annual_lst_coll.select(['lst_tpi5400', 'lst_tpi2700', 'lst_tpi270']).mean()\
var mean_lst_tpi_ms = (mean_lst_tpi.select('lst_tpi5400')\
                .add(mean_lst_tpi.select('lst_tpi2700'))\
                .add(mean_lst_tpi.select('lst_tpi270')))\
                .divide(3)\
\
\
// STEP 2.3. Combine all predictor variables into a single image \
  var predictorimage = mean_vis\
    .addBands([cv_vis, seas_cv_vis, DTG, mTPI, etaP, CTI, mean_lst_tpi_ms])\
    .updateMask(urb)  // mask out urban lands from predictor image\
    .updateMask(KG_mask2) // mask out areas outside drylands\
    .updateMask(ocean_dlc)// mask out oceans\
    .updateMask(DTG_mask) // mask out areas where DTG gte 30 m\
    .updateMask(ag);  // mask out agricultural lands from predictor image\
\
//print('predictor image',predictorimage)\
\
//Create predictor image of bands used as predictors in the random forest model\
var predictorimage_rfbands = predictorimage.select(["ETaP","CTI","lst_tpi5400","msavi","msavi_cv","ndvi", "ndvi_cv","ndwi_leaf","ndwi_leaf_cv","ndwi_water","ndwi_water_cv"])\
\
//print('predictorimage_rfbands',predictorimage_rfbands)\
\
///////////////////////////////////////////\
//  STEP 3. LOAD TRAINING DATA        //\
///////////////////////////////////////////\
\
var validation1 = ee.FeatureCollection('projects/ee-global-gde-map/assets/CrossValidation/validationpts1_withpredictors_noWestAus');\
var validation2 = ee.FeatureCollection('projects/ee-global-gde-map/assets/CrossValidation/validationpts2_withpredictors_noWestAus');\
var test = validation1.merge(validation2);\
\
var training1 = ee.FeatureCollection('projects/ee-global-gde-map/assets/CrossValidation/trainingpts1_withpredictors_noWestAus');\
var training2 = ee.FeatureCollection('projects/ee-global-gde-map/assets/CrossValidation/trainingpts2_withpredictors_noWestAus');\
var training3 = ee.FeatureCollection('projects/ee-global-gde-map/assets/CrossValidation/trainingpts3_withpredictors_noWestAus');\
var training4 = ee.FeatureCollection('projects/ee-global-gde-map/assets/CrossValidation/trainingpts4_withpredictors_noWestAus');\
var training5 = ee.FeatureCollection('projects/ee-global-gde-map/assets/CrossValidation/trainingpts5_withpredictors_noWestAus');\
var training6 = ee.FeatureCollection('projects/ee-global-gde-map/assets/CrossValidation/trainingpts6_withpredictors_noWestAus');\
var training7 = ee.FeatureCollection('projects/ee-global-gde-map/assets/CrossValidation/trainingpts7_withpredictors_noWestAus');\
var training8 = ee.FeatureCollection('projects/ee-global-gde-map/assets/CrossValidation/trainingpts8_withpredictors_noWestAus');\
var training = training1.merge(training2).merge(training3).merge(training4).merge(training5).merge(training6).merge(training7).merge(training8);\
\
\
print('Size of training',training.size())\
print('Size of test', test.size())\
\
//////////////////////////////////////////\
//  STEP 4. HYPERPARAMETER TUNING       //\
//////////////////////////////////////////\
\
// AVOID MEMORY LIMITS BY RUNNING EACH VARIABLE SEPARATELY \
\
// --- Number of Trees --- //\
// Tune the numberOfTrees parameter.\
var numTreesList = ee.List.sequence(20, 120, 10);\
\
var accuracies_trees = numTreesList.map(function(t) \{\
  var classifier = ee.Classifier.smileRandomForest(\{\
    numberOfTrees:t\})\
      .train(\{\
        features: training,\
        classProperty: 'class',\
        inputProperties: predictorimage_rfbands.bandNames()\
      \});\
\
  // Here we are classifying a table instead of an image\
  // Classifiers work on both images and tables\
  return test\
    .classify(classifier)\
    .errorMatrix('class', 'classification')\
    .accuracy();\
\});\
\
var chart = ui.Chart.array.values(\{\
  array: ee.Array(accuracies_trees),\
  axis: 0,\
  xLabels: numTreesList\
  \}).setOptions(\{\
      title: 'Hyperparameter Tuning for the numberOfTrees Parameter',\
      vAxis: \{title: 'Validation Accuracy'\},\
      hAxis: \{title: 'Number of Trees - individual', gridlines: \{count: 15\}\}\
  \});\
print(chart);\
\
\
// --- Variables Per Split --- //\
// Tune the variablesPerSplit parameter.\
var varPerSplitList = ee.List.sequence(1,6,1);\
\
var accuracies_split = varPerSplitList.map(function(s) \{\
  var classifier = ee.Classifier.smileRandomForest(\{\
    numberOfTrees:70,\
    variablesPerSplit:s\})\
      .train(\{\
        features: training,\
        classProperty: 'class',\
        inputProperties: predictorimage_rfbands.bandNames()\
      \});\
\
  // Here we are classifying a table instead of an image\
  // Classifiers work on both images and tables\
  return test\
    .classify(classifier)\
    .errorMatrix('class', 'classification')\
    .accuracy();\
\});\
\
var chart = ui.Chart.array.values(\{\
  array: ee.Array(accuracies_split),\
  axis: 0,\
  xLabels: varPerSplitList\
  \}).setOptions(\{\
      title: 'Hyperparameter Tuning for the variablesPerSplit	 Parameter',\
      vAxis: \{title: 'Validation Accuracy'\},\
      hAxis: \{title: 'Variables Per Split - individual', gridlines: \{count: 15\}\}\
  \});\
print(chart);\
\
\
\
\
// --- Minimum Leaf Population --- //\
// Tune the minLeafPopulation parameter.\
\
var minLeafPopList = ee.List.sequence(1,10,1);\
\
var accuracies_minLeafPop = minLeafPopList.map(function(l) \{\
  var classifier = ee.Classifier.smileRandomForest(\{\
    numberOfTrees:70,\
      minLeafPopulation: l\})\
      .train(\{\
        features: training,\
        classProperty: 'class',\
        inputProperties: predictorimage_rfbands.bandNames()\
      \});\
\
  // Here we are classifying a table instead of an image\
  // Classifiers work on both images and tables\
  return test\
    .classify(classifier)\
    .errorMatrix('class', 'classification')\
    .accuracy();\
\});\
\
var chart = ui.Chart.array.values(\{\
  array: ee.Array(accuracies_minLeafPop),\
  axis: 0,\
  xLabels: minLeafPopList\
  \}).setOptions(\{\
      title: 'Hyperparameter Tuning for the minLeafPopulation Parameter',\
      vAxis: \{title: 'Validation Accuracy'\},\
      hAxis: \{title: 'Minimum Leaf Population - individual', gridlines: \{count: 15\}\}\
  \});\
print(chart);\
\
\
\
// --- Bag Fraction --- //\
// Tune the bagFraction parameter.\
var bagFractionList = ee.List.sequence(0.1, 0.9, 0.2);\
\
var accuracies_bagFrac = bagFractionList.map(function(b) \{\
  var classifier = ee.Classifier.smileRandomForest(\{\
    numberOfTrees:70,\
    bagFraction:b\})\
      .train(\{\
        features: training,\
        classProperty: 'class',\
        inputProperties: predictorimage_rfbands.bandNames()\
      \});\
\
  // Here we are classifying a table instead of an image\
  // Classifiers work on both images and tables\
  return test\
    .classify(classifier)\
    .errorMatrix('class', 'classification')\
    .accuracy();\
\});\
\
var chart = ui.Chart.array.values(\{\
  array: ee.Array(accuracies_bagFrac),\
  axis: 0,\
  xLabels: bagFractionList\
  \}).setOptions(\{\
      title: 'Hyperparameter Tuning for the bagFraction Parameter',\
      vAxis: \{title: 'Validation Accuracy'\},\
      hAxis: \{title: 'Bag Fraction - individual', gridlines: \{count: 15\}\}\
  \});\
print(chart);\
\
\
\
// --- Max Nodes --- //\
// Tune the maxNodes parameter.\
var maxNodesList = ee.List.sequence(10,10000,1000);\
\
var accuracies_nodes = maxNodesList.map(function(n) \{\
  var classifier = ee.Classifier.smileRandomForest(\{\
    numberOfTrees:70,\
    maxNodes:n\})\
      .train(\{\
        features: training,\
        classProperty: 'class',\
        inputProperties: predictorimage_rfbands.bandNames()\
      \});\
\
  // Here we are classifying a table instead of an image\
  // Classifiers work on both images and tables\
  return test\
    .classify(classifier)\
    .errorMatrix('class', 'classification')\
    .accuracy();\
\});\
\
var chart = ui.Chart.array.values(\{\
  array: ee.Array(accuracies_nodes),\
  axis: 0,\
  xLabels: maxNodesList\
  \}).setOptions(\{\
      title: 'Hyperparameter Tuning for the maxNodes Parameter',\
      vAxis: \{title: 'Validation Accuracy'\},\
      hAxis: \{title: 'Maximum Nodes - individual', gridlines: \{count: 15\}\}\
  \});\
print(chart);}