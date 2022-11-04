## README for global groundwater-dependent ecosystem map code and data

### 1. Prepare masking data

**DTW_Images**

This google earth engine code is used to smooth and mask out surface water bodies from the global depth-to-groundwater database (Fan et al. 2015)

Input:

-   Fan et al. 2015 (subset by continent) - Also available as google earth engine asset (links in code)

Output:

-   GlobalDTW.tif

### 2. Generating Training Data

`SamplingCode_DTWmask.R`: This R statistical software code generates non-GDE random points within geographies with GDE training data.

Data Input:

-   GlobalDTW.tif

`RandomBareGroundPoints`: This Google Earth Engine code is used to generate non-GDE points on barren lands globally. Outputs (available as google earth engine asset): random_barren_nhem - 5000 training points from the northern hemisphere random_barren_shem - 5000 training points from the Southern Hemisphere

`LandfireTrainingData.R`: This R statistical software code classifies LANDFIRE training data into GDE and non-GDE classes.

Data inputs:

1.  *vegcamp_GDE_review_20161107.csv* - This file contains GDE certainty from California based on Klausmeyer et al. 2018.

2.  *Landfire_TrainingData.csv* - This file contains GDE confirmation based on published data and expert review (see Supplementary Table 2).

3.  *tbl_DomSp_Unique_NW_SW.csv*

Data Outputs:

*Landfire_List.csv*: This file was used to extract training data from the original LANDFIRE reference data in ArcGIS

### 3. Map Groundwater Dependent Ecosystems

`GDE_TrainingData`: This Google Earth Engine Code associates predictor variable data to training and validation points used in the GDE_RandomForest mapping model.

Inputs (located as asset in google earth engine)

-   GlobalDTW.tif (also available as a google earth engine asset - see code)

TopConvIndex_Global_KGclims (available as google earth engine asset - see code)

Beck_KG_V1_present_0p0083 (available as google earth engine asset - see code)

GlobalGDEMap_TrainingPoints_AusLandfire (available as google earth engine asset - see code) -this dataset is a shp output from ArcGIS that is based on the Landfire_List.csv output above and the Australian GDE Atlas.

Outputs (located as asset in google earth engine) trainingpts1_withpredictors trainingpts2_withpredictors trainingpts3_withpredictors trainingpts4_withpredictors trainingPts validationpts_withpredictors

**GDE_RandomForest**

This Google Earth Engine Code contains the random forest model used to map groundwater- dependent ecosystems globally.

Inputs (located as asset in google earth engine):

GlobalDTW.tif (also available as a google earth engine asset - see code)

trainingpts1_withpredictors (available as google earth engine asset - see code)

trainingpts2_withpredictors (available as google earth engine asset - see code)

trainingpts3_withpredictors (available as google earth engine asset - see code)

trainingpts4_withpredictors( available as google earth engine asset - see code)

trainingPts (available as google earth engine asset - see code)

validationpts_withpredictors (available as google earth engine asset - see code)

Output:

GDE map

---References---

Fan Y, Li H, Miguez-Macho G. Global patterns of groundwater table depth. Science. 2013 Feb 22;339(6122):940-3. doi: 10.1126/science.1229881.

Klausmeyer K., J. Howard, T. Keeler-Wolf, K. Davis-Fadtke, R. Hull, A. Lyons. 2018. Mapping Indicators of Groundwater Dependent Ecosystems in California: Methods Report. San Francisco, California.
