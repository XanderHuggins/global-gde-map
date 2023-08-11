—PRE-PROCESSING—

1. Prepare masking data

Code: 1_DTG_Images

Description: This google earth engine code is used to smooth and mask out surface water bodies from the global depth-to-groundwater database (Fan et al. 2017)

Data inputs:
	Fan et al. 2017 (subset by continent) - Also available as google earth engine asset (links in code)
	ESRI 10 m Land Use Land Cover data (available in google earth engine - see code)

Output:
	GlobalDTG (available as google earth engine asset - link in code)
	GlobalDTG.tif 

2. Generating Training Data

2.a. Random Bare Ground Training Points

Code: 2_RandomBareGroundPoints

Description: This Google Earth Engine code is used to generate non-GDE points on barren lands globally.

Data inputs:
	ESRI 10 m Land Use Land Cover data (available in google earth engine - see code)

Outputs :
	random_barren_nhem - 5000 training points from the northern hemisphere (available as google earth engine asset - link in code)
	random_barren_shem - 5000 training points from the Southern Hemisphere (available as google earth engine asset - link in code)
	
2.b. LANDFIRE Training Points

Code: 2_LandfireTrainingData.R

Description: This R statistical software code classifies LANDFIRE training data into GDE and non-GDE classes.

Data inputs:
	(i)) vegcamp_GDE_review_20161107.csv - This file contains GDE certainty from California based on Klausmeyer et al. 2018.
	(ii) Landfire_TrainingData.csv - This file contains GDE confirmation based on published data and expert review (see Supplementary Table 2).
	(iii) tbl_DomSp_Unique_NW_SW.csv  - This file contains a list of all the unique dominant species names in the LANDFIRE dataset.
Output:
	Landfire_List.csv - This file was used to extract training data from the original LANDFIRE reference data in ArcGIS.

	
2.c. Australia GDE Atlas 

Training points generated within Australia were selected using ArcMap (no code provided). These are the steps for processing the Australian GDE training points.
	
Pre-processing steps:
1. Download GDE_Atlas_Aquatic_GDEs.gdb (n=1,107,524 features) GDE_Atlas_Terrestrial_GDEs.gdb (n=7,747,955 features). Contact: water@bom.gov.au at the Australian Bureau of Meteorology for bulk download information).

2. Create separate shapefiles to subset the aquatic and terrestrial geodatabases into the following based on the “gwdep_ds” field:
- Australia_aquatic_knownGDE.shp from “Known GDE - from regional studies” in the aquatic geodatabase (GDE_Atlas_Aquatic_GDEs.gdb)   
- Australia_aquatic_LowPotential_nonGDE.shp from “Low potential GDE - from regional studies” in the terrestrial geodatabase (GDE_Atlas_Terrestrial_GDEs.gdb)
- Australia_terrestrial_knownGDE.shp from “Known GDE - from regional studies” in the aquatic geodatabase (GDE_Atlas_Aquatic_GDEs.gdb)
- Australia_terrestrial_LowPotential_nonGDE.shp from “Low potential GDE - from regional studies” in the terrestrial geodatabase (GDE_Atlas_Terrestrial_GDEs.gdb)
	
3. Remove “Karstic aquifer/cave” features from the “ecotype_ds” field in the Australia_terrestrial_knownGDE.shp and Australia_terrestrial_LowPotential_nonGDE.shp 

4. Add the following fields to each subset using the field calculator:
gde_type =  “Aquatic GDE” or “Terrestrial GDE”
gde_source = “Australia GDE Atlas”
gde_class = 1 (GDE) or 2 (non-GDE)
gde_cert = 1
gde_descr = ecotype_ds (this is an existing field in the attribute table)

5. Due to different sample sizes between the aquatic GDEs (n = 16,793 features)  and non-GDEs (n = 178,258 features), randomly select the same number of samples within each class. We selected 3000 features each for terrestrial GDEs and terrestrial non-GDEs, and 16,500 features for aquatic GDEs and aquatic non-GDEs. This resulted in 39,000 polygon features from the Australian GDE atlas that we could use as training data in our model. We selected these numbers to maximize the training dataset based on the class with the least amount of features.

6. Once the final Australian GDE Atlas training points were created we converted them to points, so that they were merged with the LANDFIRE point output from LandfireTrainingData.R script.  Note that we also had to randomly select the same number of samples for the LANDFIRE training output, which resulted in 19,261 GDE and 19,261 non-GDE points. For a grand total of 77,522 training points in the GlobalGDEMap_TrainingPoints_AusLandfire Google Earth Engine Asset and saved in the data folder of this repository.
			 
2.d. sPLOT Open Data
Code: 
	sPlotOpen_Step01_Load_data.ipynb
	sPlotOpen_Step02_Create_training_points.ipynb
	sPlotOpen_Step03_Create_training_points2.ipynb

Description: The first python code file includes the steps to import the sPLOT Open dataset and summarize all of the species found in each continent.  This table was then shared with expert reviewers to classify each species/continent combination as GDE or not GDE.  The second code file takes the results of the expert review and links it back to the sPLOT Open dataset to create the first version of the training points for the machine learning model.  The third code file imports a revised version of the expert review file and creates the final set of training points.   

Data inputs: 
Sabatini, F.M., Lenoir, J., Bruelheide, H. & the sPlot Consortium (2021) sPlotOpen – An environmentally-balanced, open-access, global dataset of vegetation plots (Version 1.0) [Dataset]. iDiv Data Repository. https://doi.org/10.25829/idiv.3474-40-3292
sPlotOpen_GDE_review_20230407.csv
sPlotOpen_GDE_review_20230407_forToderichReview_Kristina Last_KK.xlsx


Outputs: 
	sPlotOpen_GDE_points_20230418.csv

	

—MAIN MODEL TO MAP GROUNDWATER-DEPENDENT ECOSYSTEMS (GDE)—

3. Export Training Data for main model
Code: 3_GDE_TrainingData

Description: This Google Earth Engine Code associates predictor variable data to training and validation points used in the GDE_RandomForest mapping model.

Data inputs: 
	GlobalDTG (available as a google earth engine asset - see code)
	ESRI 10 m Land Use Land Cover data (available in google earth engine - see code)
	Compound Topographic Index (TopConvIndex_Global_KGclims; available as google earth engine asset - see code)
	Dryland Regions (Beck_KG_V1_present_0p0083; available as google earth engine asset - see code)
	Climate - precipitation and potential dvapotranspiration (IDAHO_EPSCOR/TERRACLIMATE; available in google earth engine - see code)
	Actual Evapotranspiration (CAS/IGSNRR/PML/V2_v017; available in google earth engine - see code)
	Landsat imagery (LANDSAT/LC08/C02/T1_L2; available in google earth engine - see code)
	GlobalGDEMap_TrainingPoints_AusLandfire (available as google earth engine asset - see code)
		 - this dataset is a shp output from ArcGIS that is based on the Landfire_List.csv output above and the Australian GDE Atlas)
	random_barren_nhem (available as google earth engine asset - see code)
	random_barren_shem (available as google earth engine asset - see code)
	sPlotOpen_GDE_points_20230418_truncated (available as google earth engine asset - link in code)

Outputs: 
	trainingpts1_withpredictors (available as google earth engine asset - link in code)
	trainingpts2_withpredictors (available as google earth engine asset - link in code)
	trainingpts3_withpredictors (available as google earth engine asset - link in code)
	trainingpts4_withpredictors (available as google earth engine asset - link in code)
	trainingpts5_withpredictors (available as google earth engine asset - link in code)
	trainingpts6_withpredictors (available as google earth engine asset - link in code)
	trainingpts7_withpredictors (available as google earth engine asset - link in code)
	trainingpts8_withpredictors (available as google earth engine asset - link in code)
	trainingPts (available as google earth engine asset - link in code)
	validationpts1_withpredictors (available as google earth engine asset - link in code)
	validationpts2_withpredictors (available as google earth engine asset - link in code)

4. Hyperparameter Tuning

Code: 4_HyperparameterTuning

Description: Retrieve optimal parameters in random forest model to achieve highest accuracy for GDE classification.

Data inputs: 
	GlobalDTG (available as a google earth engine asset - see code)
	ESRI 10 m Land Use Land Cover data (available in google earth engine - see code)
	Compound Topographic Index (TopConvIndex_Global_KGclims; available as google earth engine asset - see code)
	Dryland Regions (Beck_KG_V1_present_0p0083; available as google earth engine asset - see code)
	Climate - precipitation and potential dvapotranspiration (IDAHO_EPSCOR/TERRACLIMATE; available in google earth engine - see code)
	Actual Evapotranspiration (CAS/IGSNRR/PML/V2_v017; available in google earth engine - see code)
	Landsat imagery (LANDSAT/LC08/C02/T1_L2; available in google earth engine - see code)
	trainingpts1_withpredictors (available as google earth engine asset - link in code)
	trainingpts2_withpredictors (available as google earth engine asset - link in code)
	trainingpts3_withpredictors (available as google earth engine asset - link in code)
	trainingpts4_withpredictors (available as google earth engine asset - link in code)
	trainingpts5_withpredictors (available as google earth engine asset - link in code)
	trainingpts6_withpredictors (available as google earth engine asset - link in code)
	trainingpts7_withpredictors (available as google earth engine asset - link in code)
	trainingpts8_withpredictors (available as google earth engine asset - link in code)
	validationpts1_withpredictors (available as google earth engine asset - link in code)
	validationpts2_withpredictors (available as google earth engine asset - link in code)

Output: 
Accuracy tables and charts for numberOfTrees, variablesPerSplit, minLeafPopulation, bagFraction, and maxNodes parameters


5. Classify GDEs using the Random Forest model

Code: 5_GDE_RandomForest

Description: This Google Earth Engine Code contains the random forest model used to map groundwater-dependent ecosystems globally. 

Data inputs:
	GlobalDTG (available as a google earth engine asset - see code)
	ESRI 10 m Land Use Land Cover data (available in google earth engine - see code)
	Compound Topographic Index (TopConvIndex_Global_KGclims; available as google earth engine asset - see code)
	Dryland Regions (Beck_KG_V1_present_0p0083; available as google earth engine asset - see code)
	Climate - precipitation and potential dvapotranspiration (IDAHO_EPSCOR/TERRACLIMATE; available in google earth engine - see code)
	Actual Evapotranspiration (CAS/IGSNRR/PML/V2_v017; available in google earth engine - see code)
	Landsat imagery (LANDSAT/LC08/C02/T1_L2; available in google earth engine - see code)
	trainingpts1_withpredictors (available as google earth engine asset - link in code)
	trainingpts2_withpredictors (available as google earth engine asset - link in code)
	trainingpts3_withpredictors (available as google earth engine asset - link in code)
	trainingpts4_withpredictors (available as google earth engine asset - link in code)
	trainingpts5_withpredictors (available as google earth engine asset - link in code)
	trainingpts6_withpredictors (available as google earth engine asset - link in code)
	trainingpts7_withpredictors (available as google earth engine asset - link in code)
	trainingpts8_withpredictors (available as google earth engine asset - link in code)
	trainingPts (available as google earth engine asset - link in code)
	validationpts1_withpredictors (available as google earth engine asset - link in code)
	validationpts2_withpredictors (available as google earth engine asset - link in code)

Output:
	GDE classification 
	GDE probability
	joinval.csv
	jointrain.csv


—CROSS VALIDATION MODELS—

6. Generate Training Data for cross validation tests

6a. Sahel

Code: 6_CrossValidation_Sahel_TrainingData

Description: This Google Earth Engine code generates training data points using GDE location data from the World Bank that were extracted from peer-review literature sources, and non-GDE points from the ESRI land use and land cover bare ground layer. 

Data inputs:
	GDE lines and point data (Source: World Bank)
	ESRI 10 m Land Use Land Cover data (available in google earth engine - see code)


Output: 
	SahelGDEpts (available as google earth engine asset - link in code)
	SahelNonGDEpts (available as google earth engine asset - link in code)

6b. Western Australia
Code: 6_CrossValidation_WestAustralia_TrainingData

Description: This Google Earth Engine code generates training data points for the Western Australia cross validation test.

Data inputs:
	GlobalDTG (available as a google earth engine asset - see code)
	ESRI 10 m Land Use Land Cover data (available in google earth engine - see code)
	Compound Topographic Index (TopConvIndex_Global_KGclims; available as google earth engine asset - see code)
	Dryland Regions (Beck_KG_V1_present_0p0083; available as google earth engine asset - see code)
	Climate - precipitation and potential dvapotranspiration (IDAHO_EPSCOR/TERRACLIMATE; available in google earth engine - see code)
	Actual Evapotranspiration (CAS/IGSNRR/PML/V2_v017; available in google earth engine - see code)
	Landsat imagery (LANDSAT/LC08/C02/T1_L2; available in google earth engine - see code)
	GlobalGDEMap_TrainingPoints_AusLandfire (available as google earth engine asset - see code)
		 - this dataset is a shp output from ArcGIS that is based on the Landfire_List.csv output above and the Australian GDE Atlas)
	random_barren_nhem (available as google earth engine asset - see code)
	random_barren_shem (available as google earth engine asset - see code)
	sPlotOpen_GDE_points_20230418_truncated (available as google earth engine asset - link in code)

Output: 
	trainingpts1_withpredictors_noWestAus (available as google earth engine asset - link in code)
	trainingpts2_withpredictors_noWestAus (available as google earth engine asset - link in code)
	trainingpts3_withpredictors_noWestAus (available as google earth engine asset - link in code)
	trainingpts4_withpredictors_noWestAus (available as google earth engine asset - link in code)
	trainingpts5_withpredictors_noWestAus (available as google earth engine asset - link in code)
	trainingpts6_withpredictors_noWestAus (available as google earth engine asset - link in code)
	trainingpts7_withpredictors_noWestAus (available as google earth engine asset - link in code)
	trainingpts8_withpredictors_noWestAus (available as google earth engine asset - link in code)
	trainingPts_noWestAus (available as google earth engine asset - link in code)
	trainingPts_WestAus (available as google earth engine asset - link in code)
	validationpts1_withpredictors_noWestAus (available as google earth engine asset - link in code)
	validationpts2_withpredictors_noWestAus (available as google earth engine asset - link in code)

6c. New Mexico
Code: 6_CrossValidation_NewMexico_TrainingData

Description: This Google Earth Engine code generates training data points for the New Mexico cross validation test.

Data inputs:
	GlobalDTG (available as a google earth engine asset - see code)
	ESRI 10 m Land Use Land Cover data (available in google earth engine - see code)
	Compound Topographic Index (TopConvIndex_Global_KGclims; available as google earth engine asset - see code)
	Dryland Regions (Beck_KG_V1_present_0p0083; available as google earth engine asset - see code)
	Climate - precipitation and potential dvapotranspiration (IDAHO_EPSCOR/TERRACLIMATE; available in google earth engine - see code)
	Actual Evapotranspiration (CAS/IGSNRR/PML/V2_v017; available in google earth engine - see code)
	Landsat imagery (LANDSAT/LC08/C02/T1_L2; available in google earth engine - see code)
	GlobalGDEMap_TrainingPoints_AusLandfire (available as google earth engine asset - see code)
		 - this dataset is a shp output from ArcGIS that is based on the Landfire_List.csv output above and the Australian GDE Atlas)
	random_barren_nhem (available as google earth engine asset - see code)
	random_barren_shem (available as google earth engine asset - see code)
	sPlotOpen_GDE_points_20230418_truncated (available as google earth engine asset - link in code)

Output: 
	trainingpts1_withpredictors_noNewMexico (available as google earth engine asset - link in code)
	trainingpts2_withpredictors_noNewMexico (available as google earth engine asset - link in code)
	trainingpts3_withpredictors_noNewMexico (available as google earth engine asset - link in code)
	trainingpts4_withpredictors_noNewMexico (available as google earth engine asset - link in code)
	trainingpts5_withpredictors_noNewMexico (available as google earth engine asset - link in code)
	trainingpts6_withpredictors_noNewMexico (available as google earth engine asset - link in code)
	trainingpts7_withpredictors_noNewMexico (available as google earth engine asset - link in code)
	trainingpts8_withpredictors_noNewMexico (available as google earth engine asset - link in code)
	trainingPts_noNewMexico (available as google earth engine asset - link in code)
	trainingPts_NewMexico (available as google earth engine asset - link in code)
	validationpts1_withpredictors_noNewMexico (available as google earth engine asset - link in code)
	validationpts2_withpredictors_noNewMexico (available as google earth engine asset - link in code)

7. Hyperparameter tuning for cross validation tests

7a. Sahel

Code: 4_HyperparameterTuning

Description: Retrieve optimal parameters in random forest model to achieve highest accuracy for GDE classification.

Data inputs: 
	GlobalDTG (available as a google earth engine asset - see code)
	ESRI 10 m Land Use Land Cover data (available in google earth engine - see code)
	Compound Topographic Index (TopConvIndex_Global_KGclims; available as google earth engine asset - see code)
	Dryland Regions (Beck_KG_V1_present_0p0083; available as google earth engine asset - see code)
	Climate - precipitation and potential dvapotranspiration (IDAHO_EPSCOR/TERRACLIMATE; available in google earth engine - see code)
	Actual Evapotranspiration (CAS/IGSNRR/PML/V2_v017; available in google earth engine - see code)
	Landsat imagery (LANDSAT/LC08/C02/T1_L2; available in google earth engine - see code)
	trainingpts1_withpredictors (available as google earth engine asset - link in code)
	trainingpts2_withpredictors (available as google earth engine asset - link in code)
	trainingpts3_withpredictors (available as google earth engine asset - link in code)
	trainingpts4_withpredictors (available as google earth engine asset - link in code)
	trainingpts5_withpredictors (available as google earth engine asset - link in code)
	trainingpts6_withpredictors (available as google earth engine asset - link in code)
	trainingpts7_withpredictors (available as google earth engine asset - link in code)
	trainingpts8_withpredictors (available as google earth engine asset - link in code)
	validationpts1_withpredictors (available as google earth engine asset - link in code)
	validationpts2_withpredictors (available as google earth engine asset - link in code)

Output: 
Accuracy tables and charts for numberOfTrees, variablesPerSplit, minLeafPopulation, bagFraction, and maxNodes parameters

7b. Western Australia
Code: 7_CrossValidation_WestAustralia_HyperparameterTuning

Description: Tune parameters in random forest for West Australia cross validation test to retrieve optimal parameters to achieve highest accuracy

Data inputs:
	GlobalDTG (available as a google earth engine asset - see code)
	ESRI 10 m Land Use Land Cover data (available in google earth engine - see code)
	Compound Topographic Index (TopConvIndex_Global_KGclims; available as google earth engine asset - see code)
	Dryland Regions (Beck_KG_V1_present_0p0083; available as google earth engine asset - see code)
	Climate - precipitation and potential dvapotranspiration (IDAHO_EPSCOR/TERRACLIMATE; available in google earth engine - see code)
	Actual Evapotranspiration (CAS/IGSNRR/PML/V2_v017; available in google earth engine - see code)
	Landsat imagery (LANDSAT/LC08/C02/T1_L2; available in google earth engine - see code)
	trainingpts1_withpredictors_noWestAus (available as google earth engine asset - link in code)
	trainingpts2_withpredictors_noWestAus (available as google earth engine asset - link in code)
	trainingpts3_withpredictors_noWestAus (available as google earth engine asset - link in code)
	trainingpts4_withpredictors_noWestAus (available as google earth engine asset - link in code)
	trainingpts5_withpredictors_noWestAus (available as google earth engine asset - link in code)
	trainingpts6_withpredictors_noWestAus (available as google earth engine asset - link in code)
	trainingpts7_withpredictors_noWestAus (available as google earth engine asset - link in code)
	trainingpts8_withpredictors_noWestAus (available as google earth engine asset - link in code)
	trainingPts_noWestAus (available as google earth engine asset - link in code)
	trainingPts_WestAus (available as google earth engine asset - link in code)
	validationpts1_withpredictors_noWestAus (available as google earth engine asset - link in code)
	validationpts2_withpredictors_noWestAus (available as google earth engine asset - link in code)

Output: 
Accuracy tables and charts for numberOfTrees, variablesPerSplit, minLeafPopulation, bagFraction, and maxNodes parameters

7c. New Mexico
Code: 7_CrossValidation_NewMexico_HyperparameterTuning

Description: Tune parameters in random forest for New Mexico cross validation test to retrieve optimal parameters to achieve highest accuracy

Data inputs:
	GlobalDTG (available as a google earth engine asset - see code)
	ESRI 10 m Land Use Land Cover data (available in google earth engine - see code)
	Compound Topographic Index (TopConvIndex_Global_KGclims; available as google earth engine asset - see code)
	Dryland Regions (Beck_KG_V1_present_0p0083; available as google earth engine asset - see code)
	Climate - precipitation and potential dvapotranspiration (IDAHO_EPSCOR/TERRACLIMATE; available in google earth engine - see code)
	Actual Evapotranspiration (CAS/IGSNRR/PML/V2_v017; available in google earth engine - see code)
	Landsat imagery (LANDSAT/LC08/C02/T1_L2; available in google earth engine - see code)
	trainingpts1_withpredictors_noNewMexico (available as google earth engine asset - link in code)
	trainingpts2_withpredictors_noNewMexico (available as google earth engine asset - link in code)
	trainingpts3_withpredictors_noNewMexico (available as google earth engine asset - link in code)
	trainingpts4_withpredictors_noNewMexico (available as google earth engine asset - link in code)
	trainingpts5_withpredictors_noNewMexico (available as google earth engine asset - link in code)
	trainingpts6_withpredictors_noNewMexico (available as google earth engine asset - link in code)
	trainingpts7_withpredictors_noNewMexico (available as google earth engine asset - link in code)
	trainingpts8_withpredictors_noNewMexico (available as google earth engine asset - link in code)
	trainingPts_noNewMexico (available as google earth engine asset - link in code)
	trainingPts_NewMexico (available as google earth engine asset - link in code)
	validationpts1_withpredictors_noNewMexico (available as google earth engine asset - link in code)
	validationpts2_withpredictors_noNewMexico (available as google earth engine asset - link in code)

Output: 
Accuracy tables and charts for numberOfTrees, variablesPerSplit, minLeafPopulation, bagFraction, and maxNodes parameters


8. Perform cross validation tests

8a. Sahel
Code: 8_CrossValidation_Sahel_RandomForest

Description: This Google Earth Engine code samples the main global GDE classification output using the Sahel training points. 

Data inputs:
	GlobalDTG (available as a google earth engine asset - see code)
	ESRI 10 m Land Use Land Cover data (available in google earth engine - see code)
	Compound Topographic Index (TopConvIndex_Global_KGclims; available as google earth engine asset - see code)
	Dryland Regions (Beck_KG_V1_present_0p0083; available as google earth engine asset - see code)
	Climate - precipitation and potential dvapotranspiration (IDAHO_EPSCOR/TERRACLIMATE; available in google earth engine - see code)
	Actual Evapotranspiration (CAS/IGSNRR/PML/V2_v017; available in google earth engine - see code)
	Landsat imagery (LANDSAT/LC08/C02/T1_L2; available in google earth engine - see code)
	trainingpts1_withpredictors (available as google earth engine asset - link in code)
	trainingpts2_withpredictors (available as google earth engine asset - link in code)
	trainingpts3_withpredictors (available as google earth engine asset - link in code)
	trainingpts4_withpredictors (available as google earth engine asset - link in code)
	trainingpts5_withpredictors (available as google earth engine asset - link in code)
	trainingpts6_withpredictors (available as google earth engine asset - link in code)
	trainingpts7_withpredictors (available as google earth engine asset - link in code)
	trainingpts8_withpredictors (available as google earth engine asset - link in code)
	trainingPts (available as google earth engine asset - link in code)
	validationpts1_withpredictors (available as google earth engine asset - link in code)
	validationpts2_withpredictors (available as google earth engine asset - link in code)
	SahelGDEpts (available as google earth engine asset - link in code)
	SahelNonGDEpts (available as google earth engine asset - link in code)


Output: 
	Sahel_GDE_Sample.csv
	Sahel_nonGDE_Sample.csv


8b. Western Australia
Code: 8_CrossValidation_WestAustralia_RandomForest

Description: Cross validation test for Western Australia.

Data inputs:
	GlobalDTG (available as a google earth engine asset - see code)
	ESRI 10 m Land Use Land Cover data (available in google earth engine - see code)
	Compound Topographic Index (TopConvIndex_Global_KGclims; available as google earth engine asset - see code)
	Dryland Regions (Beck_KG_V1_present_0p0083; available as google earth engine asset - see code)
	Climate - precipitation and potential dvapotranspiration (IDAHO_EPSCOR/TERRACLIMATE; available in google earth engine - see code)
	Actual Evapotranspiration (CAS/IGSNRR/PML/V2_v017; available in google earth engine - see code)
	Landsat imagery (LANDSAT/LC08/C02/T1_L2; available in google earth engine - see code)
	trainingpts1_withpredictors_noWestAus (available as google earth engine asset - link in code)
	trainingpts2_withpredictors_noWestAus (available as google earth engine asset - link in code)
	trainingpts3_withpredictors_noWestAus (available as google earth engine asset - link in code)
	trainingpts4_withpredictors_noWestAus (available as google earth engine asset - link in code)
	trainingpts5_withpredictors_noWestAus (available as google earth engine asset - link in code)
	trainingpts6_withpredictors_noWestAus (available as google earth engine asset - link in code)
	trainingpts7_withpredictors_noWestAus (available as google earth engine asset - link in code)
	trainingpts8_withpredictors_noWestAus (available as google earth engine asset - link in code)
	trainingPts_noWestAus (available as google earth engine asset - link in code)
	trainingPts_WestAus (available as google earth engine asset - link in code)
	validationpts1_withpredictors_noWestAus (available as google earth engine asset - link in code)
	validationpts2_withpredictors_noWestAus (available as google earth engine asset - link in code)


Output: 
	CrossVal_WestAus.csv

8c. New Mexico
Code: 8_CrossValidation_NewMexico_HyperparameterTuning

Description: Cross validation test for New Mexico.

Data inputs:
	GlobalDTG (available as a google earth engine asset - see code)
	ESRI 10 m Land Use Land Cover data (available in google earth engine - see code)
	Compound Topographic Index (TopConvIndex_Global_KGclims; available as google earth engine asset - see code)
	Dryland Regions (Beck_KG_V1_present_0p0083; available as google earth engine asset - see code)
	Climate - precipitation and potential dvapotranspiration (IDAHO_EPSCOR/TERRACLIMATE; available in google earth engine - see code)
	Actual Evapotranspiration (CAS/IGSNRR/PML/V2_v017; available in google earth engine - see code)
	Landsat imagery (LANDSAT/LC08/C02/T1_L2; available in google earth engine - see code)
	trainingpts1_withpredictors_noNewMexico (available as google earth engine asset - link in code)
	trainingpts2_withpredictors_noNewMexico (available as google earth engine asset - link in code)
	trainingpts3_withpredictors_noNewMexico (available as google earth engine asset - link in code)
	trainingpts4_withpredictors_noNewMexico (available as google earth engine asset - link in code)
	trainingpts5_withpredictors_noNewMexico (available as google earth engine asset - link in code)
	trainingpts6_withpredictors_noNewMexico (available as google earth engine asset - link in code)
	trainingpts7_withpredictors_noNewMexico (available as google earth engine asset - link in code)
	trainingpts8_withpredictors_noNewMexico (available as google earth engine asset - link in code)
	trainingPts_noNewMexico (available as google earth engine asset - link in code)
	trainingPts_NewMexico (available as google earth engine asset - link in code)
	validationpts1_withpredictors_noNewMexico (available as google earth engine asset - link in code)
	validationpts2_withpredictors_noNewMexico (available as google earth engine asset - link in code)

Output: 
	CrossVal_NewMexico.csv


9. Generate confusion matrices for cross validation tests

Code: 9_CrossValidationTests_ConfusionMatrices.Rmd

Description: Generate confusion matrices for the Sahel, Western Australia, and New Mexico cross validation tests.

Data inputs:
	Sahel_GDE_Sample.csv
	Sahel_nonGDE_Sample.csv
	CrossVal_WestAus.csv
	CrossVal_NewMexico.csv

Output: 
Confusion matrices for each cross validation test.

—DISTRIBUTION PLOTS—

10. Generate Random global points within model extent to compare distribution of variables within model extent and training data used in model.

Code: 10_GlobalRandomPointGenerator

Description: This Google Earth Engine code generates 125,000 random points, retaining only those that fall within the model extent - n~33,000 global points.

Data inputs:
	GlobalDTG (available as a google earth engine asset - see code)
	ESRI 10 m Land Use Land Cover data (available in google earth engine - see code)
	Dryland Regions (Beck_KG_V1_present_0p0083; available as google earth engine asset - see code)
	
Output: 
	randomGlobalPts_validationN.csv
	randomGlobalPts_validationS.csv

11. Extract predictor variable values for each random global point from model extent

Code: 11_GlobalRandomPointSampler

Description: This Google Earth Engine code extracts predictor values at randomly generated points within the model extent to compare distributions with those of training points in the model.

Data inputs:
	GlobalDTG (available as a google earth engine asset - see code)
	ESRI 10 m Land Use Land Cover data (available in google earth engine - see code)
	Compound Topographic Index (TopConvIndex_Global_KGclims; available as google earth engine asset - see code)
	Dryland Regions (Beck_KG_V1_present_0p0083; available as google earth engine asset - see code)
	Climate - precipitation and potential dvapotranspiration (IDAHO_EPSCOR/TERRACLIMATE; available in google earth engine - see code)
	Actual Evapotranspiration (CAS/IGSNRR/PML/V2_v017; available in google earth engine - see code)
	Landsat imagery (LANDSAT/LC08/C02/T1_L2; available in google earth engine - see code)
	randomGlobalPts_validationN.csv (uploaded as asset in google earth engine)
	randomGlobalPts_validationS.csv (uploaded as asset in google earth engine)

Output: 
	globalvalpts1_withpredictors
	globalvalpts2_withpredictors
	globalvalpts3_withpredictors
	globalvalpts4_withpredictors
	globalvalpts5_withpredictors
	gloablvalPts

12. Generate distribution plots of predictor values for the global and model training points.

Code: 12_Predictor_DistributionPlots.Rmd

Description: Generates overlapping distribution plots and statistics using the overlapping package in R 
(Source: https://www.rdocumentation.org/packages/overlapping/versions/2.1)

Data inputs:
	globalvalpts1_withpredictors
	globalvalpts2_withpredictors
	globalvalpts3_withpredictors
	globalvalpts4_withpredictors
	globalvalpts5_withpredictors
	gloablvalPts
	trainingpts1_withpredictors (available as google earth engine asset - link in code)
	trainingpts2_withpredictors (available as google earth engine asset - link in code)
	trainingpts3_withpredictors (available as google earth engine asset - link in code)
	trainingpts4_withpredictors (available as google earth engine asset - link in code)
	trainingpts5_withpredictors (available as google earth engine asset - link in code)
	trainingpts6_withpredictors (available as google earth engine asset - link in code)
	trainingpts7_withpredictors (available as google earth engine asset - link in code)
	trainingpts8_withpredictors (available as google earth engine asset - link in code)
	trainingPts (available as google earth engine asset - link in code)
	validationpts1_withpredictors (available as google earth engine asset - link in code)
	validationpts2_withpredictors (available as google earth engine asset - link in code)
	joinval.csv
	jointrain.csv

Output:
Distribution plots and statistics

—REFERENCES—

Fan, Y., Miguez-Macho, G., Jobbágy, E. G., Jackson, R. B. & Otero-Casal, C. Hydrologic regulation of plant rooting depth. Proc National Acad Sci 114, 10572–10577 (2017). 

Klausmeyer K., J. Howard, T. Keeler-Wolf, K. Davis-Fadtke, R. Hull, A. Lyons. 2018. Mapping Indicators of Groundwater Dependent Ecosystems in California: Methods Report. San Francisco, California.

