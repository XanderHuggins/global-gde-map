library(terra)
library(tidyverse)
library(sf)
library(here)

## 30 arcminute (50 km) ------------ \\\\ 
# 
gde_layer = terra::rast("D:/Geodatabase/GDEs/GDE_data_deposit_v6/GDE_30arcmin.tif")

# develop a flag for where GDE area is NA but analyzed area > 0
flag_r = rast(gde_layer)
flag_r$f = NA

# bring in the GDE area data and set NAs to 0 for easier notation
flag_r$gde_sqm = gde_layer$GDE_sqm
flag_r$gde_sqm[is.na(flag_r$gde_sqm)] = 0

# set the flag for where no GDE area in grid cells with analyzed area
flag_r$f[flag_r$gde_sqm == 0 & gde_layer$AA_sqm > 0] = 1

# set values to 0 rather than NA for these grid cells
# do this for GDE area and for fractions including GDE areas
gde_layer$GDE_sqm[flag_r$f == 1] = 0
gde_layer$GDE_frac_AA[flag_r$f == 1] = 0
gde_layer$GDE_frac_GA[flag_r$f == 1] = 0

writeRaster(x = gde_layer, filename = "D:/Geodatabase/GDEs/GDE_data_deposit_v6/Upload/GDE_30arcmin.tif",
            overwrite = T, wopt=list(datatype="INT4U"))

## 05 arcminute (10 km) ------------ \\\\ 
# 
gde_layer = terra::rast("D:/Geodatabase/GDEs/GDE_data_deposit_v6/GDE_05arcmin.tif")

# develop a flagfor where GDE area is NA but analyzed area > 0
flag_r = rast(gde_layer)
flag_r$f = NA

# bring in the GDE area data and set NAs to 0 for easier notation
flag_r$gde_sqm = gde_layer$GDE_sqm
flag_r$gde_sqm[is.na(flag_r$gde_sqm)] = 0

# set the flag for where no GDE area in grid cells with analyzed area
flag_r$f[flag_r$gde_sqm == 0 & gde_layer$AA_sqm > 0] = 1

# set values to 0 rather than NA for these grid cells
# do this for GDE area and for fractions including GDE areas
gde_layer$GDE_sqm[flag_r$f == 1] = 0
gde_layer$GDE_frac_AA[flag_r$f == 1] = 0
gde_layer$GDE_frac_GA[flag_r$f == 1] = 0

writeRaster(x = gde_layer, filename = "D:/Geodatabase/GDEs/GDE_data_deposit_v6/Upload/GDE_05arcmin.tif",
            overwrite = T, wopt=list(datatype="INT4U"))

## 30 arcsecond (10 km) ------------ \\\\ 
# 
gde_layer = terra::rast("D:/Geodatabase/GDEs/GDE_data_deposit_v6/GDE_30arcsec.tif")

# develop a flagfor where GDE area is NA but analyzed area > 0
flag_r = rast(gde_layer)
flag_r$f = NA

# bring in the GDE area data and set NAs to 0 for easier notation
flag_r$gde_sqm = gde_layer$GDE_sqm
flag_r$gde_sqm[is.na(flag_r$gde_sqm)] = 0

# set the flag for where no GDE area in grid cells with analyzed area
flag_r$f[flag_r$gde_sqm == 0 & gde_layer$AA_sqm > 0] = 1

# set values to 0 rather than NA for these grid cells
# do this for GDE area and for fractions including GDE areas
gde_layer$GDE_sqm[flag_r$f == 1] = 0
gde_layer$GDE_frac_AA[flag_r$f == 1] = 0
gde_layer$GDE_frac_GA[flag_r$f == 1] = 0

writeRaster(x = gde_layer, filename = "D:/Geodatabase/GDEs/GDE_data_deposit_v6/Upload/GDE_30arcsec.tif",
            overwrite = T, wopt=list(datatype="INT4U"))