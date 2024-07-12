library(readr)
library(tibble)
library(sp)
library(raster)
library(terra)
library(data.table)
library(rasterDT)

# set the current iteration
i = as.numeric(commandArgs(trailingOnly = TRUE))

# conduct analysis in the following order:
# 1/ basic area summary, calculated at base 30m resolution 
# 2/ protected status, so this can be accomplished at the base 30m resolution
# 3/ calculate the continental coverage, also at 30m resolution
# 4/ derive rasters at aggregated scales (30 arcsec/1km; 5 arcmin/10km; 30 arcmin/50km), 
# .... which the other analyses can be performed in serial

## PREPROCESSING ------------ \\\\

gde_tiles_f = list.files(path = "./input_data/GDE_v6", full.names = T)

# import the raster tile
gde_tile = rast(gde_tiles_f[i])[[1]] # first layer is GDE classification

# snap the extent as there can be decimal issues with base data
terra::ext(gde_tile) = round(terra::ext(gde_tile), 0)

# generate the cell size
area_r = terra::cellSize(gde_tile, unit = "km")

# calculate base area summary statistic
zonal_df = rasterDT::zonalDT(x = raster(area_r), z = raster(gde_tile), fun = sum, na.rm = T) |> as_tibble()
write_rds(x = zonal_df, file = paste0("./data_out/gde_dat/gde_area_tile_", i, ".rds"))

# import the three layers of the WDPA database and crop to tile extent
wdpa_1_c = terra::crop(x = vect("./input_data/WDPA_Jun2023_Public_shp-polygons_0.shp"), y = terra::ext(gde_tile))
wdpa_2_c = terra::crop(x = vect("./input_data/WDPA_Jun2023_Public_shp-polygons_1.shp"), y = terra::ext(gde_tile))
wdpa_3_c = terra::crop(x = vect("./input_data/WDPA_Jun2023_Public_shp-polygons_2.shp"), y = terra::ext(gde_tile))
wdpa_all = rbind(wdpa_1_c, wdpa_2_c, wdpa_3_c)

# separate protected areas into "high" and "low" protection classes
high_classes = c('Ia', 'Ib', 'II', 'III', 'Not Assigned', 'Not Reported')
low_classes = c('IV', 'V', 'VI', 'Not Applicable')

wdpa_all$prot_class = 1
wdpa_all$prot_class[wdpa_all$IUCN_CAT %in% high_classes] = 3
wdpa_all$prot_class[wdpa_all$IUCN_CAT %in% low_classes] = 2

# simplify the wdpa vector
wdpa_all = wdpa_all[, c("prot_class")]

# import and do same for jurisdictions
juris_prot_c = terra::crop(x = vect("./input_data/all_juris_with_GDE_protection_policies.sqlite"), y = terra::ext(gde_tile))
juris_prot_c$prot_class = 6
juris_prot_c = juris_prot_c[, c("prot_class")]

# rasterize the WDPA protected status
if (nrow(wdpa_all) == 0 ) {
  prot_status_wdpa_r = terra::rast(x = area_r, vals = 0)
}

if (nrow(wdpa_all) > 0 ) {
  prot_status_wdpa_r  = terra::rasterize(x = wdpa_all, y = area_r, field = "prot_class", touches = TRUE)
  prot_status_wdpa_r[is.na(prot_status_wdpa_r)] = 0
}

# rasterize the jurisdiction protected status
if (nrow(juris_prot_c) == 0 ) {
  prot_status_juris_r = terra::rast(x = area_r, vals = 0)
}

if (nrow(juris_prot_c) > 0 ) {
  prot_status_juris_r = terra::rasterize(x = juris_prot_c, y = area_r, field = "prot_class", touches = TRUE)
  prot_status_juris_r[is.na(prot_status_juris_r)] = 0
}

# create raster of combined protected status
prot_status_r = prot_status_wdpa_r + prot_status_juris_r

# also need gridded data on continental extents
conts = terra::vect("./input_data/Continents.shp")
conts$OBJECTID[conts$OBJECTID == 5] = 3 # combine Australia and Oceania
conts$OBJECTID[conts$OBJECTID == 8] = 5 # Move Europe to ID 5
conts$OBJECTID[conts$OBJECTID == 7] = NA # Remove Antarctica

conts_c = terra::crop(x = conts, y = terra::ext(gde_tile))

if (nrow(conts_c) == 0 ) { # for small island regions with no continental polygons (little-no effect on summary statistics)
    conts_r = terra::rast(x = area_r, vals = 0)
  }
  if (nrow(conts_c) > 0 ) {
    conts_cb = terra::buffer(x = conts_c, width = 1000) # in case there are differences in coastline between datasets, this is 1km buffer so should be fine for 30m data
    conts_r = terra::rasterize(x = conts_cb, y = area_r, field = "OBJECTID", touches = TRUE)
    conts_r[is.na(conts_r)] = 0
  }

## ANALYSIS ------------ \\\\ 

############### READ ME
## RASTER VALUES: gde_tile
## 2 : not likely GDE 
## 1 : likely GDE
## 0 : not analyzed 

## RASTER VALUES: prot_status_r
## 9 : high level of protection + policy
## 8 : low level of protection  + policy
## 7 : unknown protection class + policy 
## 6 : policy but no protection class
## 3 : high level of protection
## 2 : low level of protection
## 1 : unknown protection class
## 0 : no protection
############### end readme

## Create unique raster ID for combinations of GDE class, protected status, and continental membership
# XYW, where X is GDE class, Y is protected status, W is continental membership

gdeXprotXcont = (100*gde_tile) + (10*prot_status_r) + conts_r
zonal_df = rasterDT::zonalDT(x = raster(area_r), z = raster(gdeXprotXcont), fun = sum, na.rm = T) |> as_tibble()
write_rds(x = zonal_df, file = paste0("./data_out/gdeXprotXcont_dat/gdeXprotXcont_tile_", i, ".rds"))

## AGGREGATING ------------ \\\\ 

# create a binary map of (1) GDE area, (2) analyzed area [ANL], and (3) all area [ALL]
gde_binary = terra::classify(x = gde_tile,
                             rcl = data.frame(from = c(2), 
                                              to   = c(0)) |> as.matrix())

anl_binary = terra::classify(x = gde_tile,
                             rcl = data.frame(from = c(2), 
                                              to   = c(1)) |> as.matrix())

# mask out non-GDE areas to create a raster of only GDE area
gde_area = terra::mask(x = area_r,
                       mask = gde_binary,
                       maskvalues = 0)

# mask out not analyzed areas to create a raster of all analyzed areas (GDE or not GDE)
anl_area = terra::mask(x = area_r,
                       mask = anl_binary,
                       maskvalues = 0)


# Aggregate to three alternate resoltuions 

## gde area
gde_area_30arcsec = terra::aggregate(x = gde_area, fact = 30/1, fun = "sum", na.rm = T)
gde_area_05arcmin = terra::aggregate(x = gde_area_30arcsec, fact = 5/0.5, fun = "sum", na.rm = T)
gde_area_30arcmin = terra::aggregate(x = gde_area_05arcmin, fact = 30/5, fun = "sum", na.rm = T)

## analysed area
anl_area_30arcsec = terra::aggregate(x = anl_area, fact = 30/1, fun = "sum", na.rm = T)
anl_area_05arcmin = terra::aggregate(x = anl_area_30arcsec, fact = 5/0.5, fun = "sum", na.rm = T)
anl_area_30arcmin = terra::aggregate(x = anl_area_05arcmin, fact = 30/5, fun = "sum", na.rm = T)

## all area
all_area_30arcsec = terra::aggregate(x = area_r, fact = 30/1, fun = "sum", na.rm = T)
all_area_05arcmin = terra::aggregate(x = all_area_30arcsec, fact = 5/0.5, fun = "sum", na.rm = T)
all_area_30arcmin = terra::aggregate(x = all_area_05arcmin, fact = 30/5, fun = "sum", na.rm = T)


# calculate densities 

## 30 arcsecond
gde_to_anl_30arcsec = gde_area_30arcsec / anl_area_30arcsec
gde_to_all_30arcsec = gde_area_30arcsec / all_area_30arcsec

## 5 arcmniute
gde_to_anl_05arcmin = gde_area_05arcmin / anl_area_05arcmin
gde_to_all_05arcmin = gde_area_05arcmin / all_area_05arcmin

## 30 arcminute
gde_to_anl_30arcmin = gde_area_30arcmin / anl_area_30arcmin
gde_to_all_30arcmin = gde_area_30arcmin / all_area_30arcmin

# percent of area analysed
anl_to_all_30arcsec = anl_area_30arcsec / all_area_30arcsec
anl_to_all_05arcmin = anl_area_05arcmin / all_area_05arcmin
anl_to_all_30arcmin = anl_area_30arcmin / all_area_30arcmin

######-
# create raster stacks at each resolution

## 30 arcsecond
stack_30arcsec = c(gde_area_30arcsec, gde_to_anl_30arcsec, gde_to_all_30arcsec, 
                   anl_area_30arcsec, anl_to_all_30arcsec)
names(stack_30arcsec) = c('GDE_sqkm', 'GDE_frac_AA', 'GDE_frac_GA',
                          'AA_sqkm', 'AA_frac_GA')


## 5 arcminute
stack_05arcmin = c(gde_area_05arcmin, gde_to_anl_05arcmin, gde_to_all_05arcmin, 
                   anl_area_05arcmin, anl_to_all_05arcmin)
names(stack_05arcmin) = c('GDE_sqkm', 'GDE_frac_AA', 'GDE_frac_GA',
                          'AA_sqkm', 'AA_frac_GA')

## 30 arcminute
stack_30arcmin = c(gde_area_30arcmin, gde_to_anl_30arcmin, gde_to_all_30arcmin, 
                   anl_area_30arcmin, anl_to_all_30arcmin)
names(stack_30arcmin) = c('GDE_sqkm', 'GDE_frac_AA', 'GDE_frac_GA',
                          'AA_sqkm', 'AA_frac_GA')


######-
# write to file 
terra::writeRaster(x = stack_30arcsec,
                   filename = paste0("./raster_out/aggregations/1_30arcsec/gde_tile_", i, ".tif"),
                   overwrite = T)

terra::writeRaster(x = stack_05arcmin,
                   filename = paste0("./raster_out/aggregations/2_05arcmin/gde_tile_", i, ".tif"),
                   overwrite = T)

terra::writeRaster(x = stack_30arcmin,
                   filename = paste0("./raster_out/aggregations/3_30arcmin/gde_tile_", i, ".tif"),
                   overwrite = T)