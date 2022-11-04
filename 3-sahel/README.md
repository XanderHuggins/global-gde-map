README -- TNC GDE Maps
August 30, 2022
A. Sharman

Maps produced by the World Bank groundwater team for TNC-GDE whitepaper. All maps were made in QGIS (see "data/gwflagship_gde_tnc_maps.qgz") and are saved in two high-res formats .png and .tiff in the "maps" folder.
Maps 1-3 are at the "Greater Sahel" level, which is the GDE-areas in/near the Sahel
Map4 is at the global level

NOTE: You will likely need to clear out the files (not the folders) in "data/tnc_gde" and rerun "scripts/tnc_gde_vrt_tile_index.py" to get the correct file-paths for your computer in the TNC-GDE tile index and VRT in order for it to load correctly in QGIS and to work with it in R.

#---------------------
# Maps
#---------------------
map1_gde_pastoral :: GDEs and pastoral lands with transhumance pathways (Greater Sahel)
	The Nature Conservancy GDEs overlayed on pastureland (masked to the Greater Sahel) from Ramankutty et al. (2008) w/ transhumance pathways digitized from Corniaux et al (2016).
	
map2_hotspots_fragility :: Transboundary fragility hotspot clusters Greater Sahel)
	Conflict-GDE ("Fragility") clusters* in yellow over 0.5 degree hex grid cells colored by conflict no. events and outline in blue if in top 15% of GDE cells (by # of GDE pixels, normalized by area).
	
	Fragility clusters and GDE-conflict hex grid: We found conflict clusters by overlaying a hexagonal 0.5 degree grid cell (limited to the Greater Sahel) over ACLED (Armed Conflict Location & Event Data) point data and (The Nature Conservancy) GDE raster data. We calculated counts of all ACLED conflicts (from 1997 to Feb. 2, 2021) and all GDE pixels by hexagonal cell. We then flagged “fragile” cells as the top quarter of cells by GDE count (normalized by area) with conflict count in the top 10% of all cells (normalized by area). Next, we clustered these “fragile” cells using the DBSCAN algorithm, with a neighbor distance (epsilon) of 2 degrees and keeping clusters with at least 4 cells. The resulting cluster definitions were used to create cluster shapes from taking the convex hull of the cluster cells for each cluster. To create the final shapes, we dissolved the hexagon cells overlapping by at least half their area with the convex shapes. Final cluster shapes and gridded data w/ attributes are in "data/final_grids". **See "scripts/conflict_clusters.R"**
  
map3_food_security :: Food insecurity in October 2021. Food security data is at the district level from the Famine Early Warning Systems Network (FEWS). (Greater Sahel)
	FEWS (Famine Early Warning Systems Network) portal food security shapefiles for October 2021 masked to the Greater Sahel and colored using the Integrated Phase Classification system used by FEWS; Fragility - GDE hotspot clusters based on TNC GDE and ACLED conflict data.
	
map4_global_gde_pastoral :: GDEs and pastoral lands (World)
	The Nature Conservancy GDEs overlayed on pastureland from Ramankutty et al. (2008).

### Archived
archive_map2_hotspots_fragility :: Transboundary fragility - GDE hotspot clusters (Greater Sahel) Version 1: GDE overlayed on Heat Map
	Based on TNC GDE and ACLED conflict data
	Same clusters as identified in map2_hotspots_fragility + The Nature Conservancy GDEs overlayed onto a 5km kernal-smoothed density (KDE) raster at the .5km pixel level produced in QGIS w/ Armed Conflict Location & Event Data (all events between January 1997 and February 2, 2021 filtered to Africa) and then clipped to the Greater Sahel region.

#---------------------
## Pastureland numbers
#---------------------
Calculation of % pastoral GDEs using raster overlap (zonal statistics) of TNC & Ramankutty(2008) pastoral data (no data converted to 0 in order to get accurate % of lands that are pasture) zonal statistics at 0.5 degree clipped-to-continent, no antarctica grid cell level (and limited to greater sahel for the first line). See "scripts/percent_pastoral.R"
Prints out lines to console:
	"In the Greater Sahel, 79.8% of GDEs (16,702 km2) exist on pastoral lands which make up 68.5% of the landscape."
	"Globally, 78% of GDEs (160,980 km2) exist within pastoral lands."


#---------------------
## Sources
#---------------------
-- Corniaux, Christian & Ancey, Véronique & Ibra, Toure & Diao Camara, Astou & Cesaro, Jean-Daniel. (2016). Pastoral mobility, from a Sahelian to a sub-regional issue.

-- Food security classification shapefiles for October 2021 at the district level downloaded from the FEWS (Famine Early Warning Systems Network) data portal (https://fews.net/fews-data/).

-- Raleigh, Clionadh, Andrew Linke, Håvard Hegre and Joakim Karlsen. (2010). “Introducing ACLED-Armed Conflict Location and Event Data.” Journal of Peace Research 47(5) 651-660.

-- Ramankutty, N., A. T. Evan, C. Monfreda, and J. A. Foley. (2008). “Farming the planet: 1. Geographic distribution of global agricultural lands in the year 2000.” Global Biogeochemical Cycles 22: GB1003. http://dx.doi.org/10.1029/2007GB002952.

-- The Nature Conservancy. Groundwater Dependent Ecosystems (forthcoming)...