library(terra)
library(tidyverse)
library(sf)
library(here)

## 30 arcminute (50 km) ------------ \\\\ 
# 
gde_stack = list.files("D:/Geodatabase/GDEs/Processed_GDE_layers/raster_out/aggregations/3_30arcmin/", pattern = ".tif$", full.names = T)
gde_stack = gde_stack |> lapply(rast)
gde_stack = terra::sprc(gde_stack)
gde_30arcmin = terra::merge(gde_stack)

# convert square kilometers to square meters
gde_30arcmin$GDE_sqkm = 1e6*gde_30arcmin$GDE_sqkm
names(gde_30arcmin)[1] = "GDE_sqm"

gde_30arcmin$AA_sqkm = 1e6*gde_30arcmin$AA_sqkm
names(gde_30arcmin)[4] = "AA_sqm"

# multiply by 1e4 to enable saving as integer file type
gde_30arcmin$GDE_frac_AA =  1e8*gde_30arcmin$GDE_frac_AA 
gde_30arcmin$GDE_frac_GA =  1e8*gde_30arcmin$GDE_frac_GA 
gde_30arcmin$AA_frac_GA  =   1e8*gde_30arcmin$AA_frac_GA
names(gde_30arcmin) = c("GDE_sqm", "GDE_frac_AA", "GDE_frac_GA", "AA_sqm", "AA_frac_GA")

gde_30arcmin = round(gde_30arcmin, 0) # enables saving as INT
writeRaster(x = gde_30arcmin, filename = "D:/Geodatabase/GDEs/GDE_data_deposit_v6/GDE_30arcmin.tif",
            overwrite = T, wopt=list(datatype="INT4U"))

## 05 arcminute (10 km) ------------ \\\\ 
# 
gde_stack = list.files("D:/Geodatabase/GDEs/Processed_GDE_layers/raster_out/aggregations/2_05arcmin/", pattern = ".tif$", full.names = T)
gde_stack = gde_stack |> lapply(rast)
gde_stack = terra::sprc(gde_stack)
gde_05arcmin = terra::merge(gde_stack)

# convert square kilometers to square meters
gde_05arcmin$GDE_sqkm = 1e6*gde_05arcmin$GDE_sqkm
names(gde_05arcmin)[1] = "GDE_sqm"

gde_05arcmin$AA_sqkm = 1e6*gde_05arcmin$AA_sqkm
names(gde_05arcmin)[4] = "AA_sqm"

# multiply by 1e4 to enable saving as integer file type
gde_05arcmin$GDE_frac_AA =  1e8*gde_05arcmin$GDE_frac_AA 
gde_05arcmin$GDE_frac_GA =  1e8*gde_05arcmin$GDE_frac_GA 
gde_05arcmin$AA_frac_GA =   1e8*gde_05arcmin$AA_frac_GA
names(gde_05arcmin) = c("GDE_sqm", "GDE_frac_AA", "GDE_frac_GA", "AA_sqm", "AA_frac_GA")

gde_05arcmin = round(gde_05arcmin, 0) # enables saving as INT
writeRaster(x = gde_05arcmin, filename = "D:/Geodatabase/GDEs/GDE_data_deposit_v6/GDE_05arcmin.tif",
            overwrite = T, wopt=list(datatype="INT4U"))

## 30 arcsecond (1km) ------------ \\\\ 
# 
gde_stack = list.files("D:/Geodatabase/GDEs/Processed_GDE_layers/raster_out/aggregations/1_30arcsec/", pattern = ".tif$", full.names = T)
gde_stack = gde_stack |> lapply(rast)
gde_stack = terra::sprc(gde_stack)
gde_30arcsec = terra::merge(gde_stack)

# convert square kilometers to square meters
gde_30arcsec$GDE_sqkm = 1e6*gde_30arcsec$GDE_sqkm
names(gde_30arcsec)[1] = "GDE_sqm"

gde_30arcsec$AA_sqkm = 1e6*gde_30arcsec$AA_sqkm
names(gde_30arcsec)[4] = "AA_sqm"

# multiply by 1e4 to enable saving as integer file type
gde_30arcsec$GDE_frac_AA =  1e8*gde_30arcsec$GDE_frac_AA 
gde_30arcsec$GDE_frac_GA =  1e8*gde_30arcsec$GDE_frac_GA 
gde_30arcsec$AA_frac_GA =   1e8*gde_30arcsec$AA_frac_GA
names(gde_30arcsec) = c("GDE_sqm", "GDE_frac_AA", "GDE_frac_GA", "AA_sqm", "AA_frac_GA")

gde_30arcsec = round(gde_30arcsec, 0) # enables saving as INT
writeRaster(x = gde_30arcsec, filename = "D:/Geodatabase/GDEs/GDE_data_deposit_v6/GDE_30arcsec.tif",
            overwrite = T, wopt=list(datatype="INT4U"))