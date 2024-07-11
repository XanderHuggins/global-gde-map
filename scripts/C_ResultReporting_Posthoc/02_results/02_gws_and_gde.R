library(here)
library(terra)
library(tidyverse)

# import groundwater storage trend data
gws_trend_vic = terra::rast("D:/Geodatabase/GRACE/GWS_trend/gldas_2.1_vic_local_trends.nc")
gws_trend_noah = terra::rast("D:/Geodatabase/GRACE/GWS_trend/gldas_2.1_noah_local_trends.nc")

gws_trends = c(gws_trend_vic$gw_slope, gws_trend_noah$gw_slope) |> mean()

# this data is in km3/yr, so convert to mm @ pixel level by (1) converting km3 to m3, and (2) dividing my cell area
gws_trends = gws_trends * 1e9 # km3/yr to m3/yr
gws_trends = gws_trends / terra::cellSize(gws_trends, unit = "m") # m3/yr to m/yr as cell size is in m2 units
gws_trends = gws_trends*1000 # convert m/yr to mm/yr
names(gws_trends) = "gws_mm_yr"

writeRaster(gws_trends, "D:/Geodatabase/GRACE/GWS_trend/gws_mm_yr_2002_2023.tif")

# import the global GDE data and compare to the GRACE data
gde_30arcminute = terra::rast("D:/Geodatabase/GDEs/GDE_data_deposit_v6/Upload/GDE_30arcmin.tif")
gde_30arcminute = terra::extend(x = gde_30arcminute, y = gws_trends)

summ_stat = c(gws_trends, gde_30arcminute$GDE_sqm) |> as_tibble() 

gde_losing = summ_stat |> dplyr::filter(gws_mm_yr <0) |> pull(GDE_sqm) |> sum(na.rm = T)/1e6
gde_losing
#> 3806721 km2, 
#> ~3.8 million km2 of GDEs in regions with losing groundwater storage trends

gde_withdat = summ_stat |> dplyr::filter(gws_mm_yr  > -Inf) |> pull(GDE_sqm) |> sum(na.rm = T)/1e6
gde_withdat
#> 7201217 km2
#> ~7.2 million km2 of GDEs in regions with groundwater storage trend data

gde_losing / gde_withdat
#> 0.5286219
#> 53% of GDEs with groundwater storage trend data are in regions with negative storage trends

##
### Now generate bivariable plot comparing GDE area density with GWS trend ------ \\
##

# reclassify GDE density into discrete bins
rcl.m = c(0  , 0.01, 1,
          0.01, 0.025, 2,
          0.025, 0.05, 3,
          0.05, 0.1, 4,
          0.1, 0.2, 5,
          0.2, 0.4, 6,
          0.4, Inf, 7) |> 
  matrix(ncol = 3, byrow = TRUE)

gde_density_class = terra::classify(x = gde_30arcminute$GDE_frac_GA/1e8, rcl = rcl.m, include.lowest = TRUE)

# reclassify GWS into discrete bins, based on absolute magnitude percentils
gw_ptls = c(gws_trends, gde_30arcminute$GDE_sqm |> as.numeric(), WGS84_areaRaster(0.5) |> rast()) |> 
  as.data.frame() |> set_colnames(c('gws', 'gde_area', 'area')) |> 
  drop_na() |> 
  mutate(gws = abs(gws)) |> 
  reframe(
    wtd.quantile(x = gws, q = c(0.5, 0.75, 0.90), weight = gde_area, na.rm = T)
  ) |> as.vector() |> unlist()

rcl.m = c(-Inf, -gw_ptls[3], 1,
          -gw_ptls[3], -gw_ptls[2], 2,
          -gw_ptls[2], -gw_ptls[1], 3,
          -gw_ptls[1], gw_ptls[1], 4,
          gw_ptls[1], gw_ptls[2], 5,
          gw_ptls[2], gw_ptls[3], 6,
          gw_ptls[3], Inf, 7) |> 
  matrix(ncol = 3, byrow= TRUE)

gws_class = terra::classify(x = gws_trends, rcl = rcl.m, include.lowest = TRUE)

# Create unique bivariate class
gde_gws = (gde_density_class * 10) + (gws_class)

writeRaster(x = gde_gws, filename = here("data/gde_density_X_gws_trend_bivariate_map.tif"), overwrite = TRUE)


##
### Now calculate groundwater storage trends per GDE across continents ------ \\
##

conts = terra::vect("D:/Geodatabase/Admin-ocean-boundaries/continents/Continents.shp") |> 
  terra::rasterize(y = gde_30arcminute, field = "OBJECTID", touches = T) |> 
  terra::resample(y = gde_30arcminute, method = "near") |> 
  terra::classify(rcl = matrix(c(5, 3,   # Combine Australia and Oceania
                                 8, 5,   # Move Europe to value 5
                                 7, NA), # Remove Antactica
                               ncol = 2, byrow = TRUE))

gde_df = c(gde_30arcminute$GDE_sqm, gws_trends, conts) |> 
  as.data.frame() |> 
  set_colnames(c('gde', 'gws', 'conts')) |> 
  drop_na()

lut_names = data.frame( # names for look-up table (lut)
  id = seq(1,6),
  nm = c("AF", "AS", "OC", "NA", "EU", "SA")
)

for (i in 1:6) {
  gde_area_dry = gde_df |> filter(conts == i) |> filter(gws < 0) |> pull(gde) |> sum(na.rm = T)
  gde_area_tot = gde_df |> filter(conts == i) |> pull(gde) |> sum(na.rm = T)
  
  message("continent ", lut_names$nm[i], " had a drying GDE percentage of: ", round(100*gde_area_dry/gde_area_tot, 2))
  
}

## Key summary statistics
#> continent AF had a drying GDE percentage of: 17.02
#> continent AS had a drying GDE percentage of: 75.29
#> continent OC had a drying GDE percentage of: 29.44
#> continent NA had a drying GDE percentage of: 65.16
#> continent EU had a drying GDE percentage of: 90.18
#> continent SA had a drying GDE percentage of: 36.55

##
### Now determine GDE density vs GWS trend per FEOW ------ \\
##

# import feow file
feow = terra::vect("D:/Geodatabase/Ecological/Ecoregions/data/commondata/data0/feow_ecoregions.shp") |> as.data.frame()

feow_r = terra::vect("D:/Geodatabase/Ecological/Ecoregions/data/commondata/data0/feow_ecoregions.shp") |> 
  rasterize(y = gde_gws, field = "ECO_ID", touches = T)

feow_stat = c(feow_r, gde_30arcminute$GDE_frac_GA/1e8 |> as.numeric(), gws_trends, gde_30arcminute$GDE_sqm/1e6 |> as.numeric(), 
              WGS84_areaRaster(0.5) |> rast()) |> 
  as.data.frame() |> 
  set_colnames(c('feowid', 'gde_dens', 'gws', 'gde_area', 'area')) |> 
  drop_na() |>
  group_by(feowid) |> 
  reframe(
    gded = sum(gde_area, na.rm = T) / sum(area, na.rm = T),
    gdea = sum(gde_area, na.rm = T),
    gws  = stats::weighted.mean(x = gws, w = gde_area, na.rm = T)
  )

# identify which bin to place ID label for given FEOW
feow_stat |> filter(feowid == 125) # Sacramento - San Joaquin
feow_stat |> filter(feowid == 340) # Cuyan - Desaguadero
# feow_stat |> filter(feowid == 348) # Patagonia
# feow_stat |> filter(feowid == 448) # Kavir & Lut Deserts
feow_stat |> filter(feowid == 450) # Turan Plain
feow_stat |> filter(feowid == 509) # Senegal - Gambia
feow_stat |> filter(feowid == 569) # Okavango
feow_stat |> filter(feowid == 703) # Lower & Middle Indus
feow_stat |> filter(feowid == 806) # Lake Eyre Basin
