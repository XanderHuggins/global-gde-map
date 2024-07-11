library(magrittr)
library(tidyverse)
library(terra)

gde = terra::rast("D:/Geodatabase/GDEs/GDE_data_deposit_v6/GDE_05arcmin.tif")
pasture = terra::rast("D:/Geodatabase/Agriculture/Ramankutty/Raw/Pasture2000_5m.tif")

rcl.mat = c(seq(0, 0.8, by = 0.2,),
            seq(0.2, 1, by = 0.2),
            seq(1, 5, by = 1)) |> 
  matrix(ncol = 3)
rcl.mat[5,2] = Inf

gde_c = terra::classify(x = gde$GDE_frac_GA/1e8, rcl = rcl.mat, include.lowest = T)
pst_c = terra::classify(x = pasture, rcl = rcl.mat, include.lowest = T)

pst_c = terra::crop(pst_c, gde_c)

bivar = gde_c*10 + pst_c

# writeRaster(bivar, filename = here("data/BIVAR_gde_density_and_pasture_density_v2.tif"))

# calculate GDE area in regions with >0.25% pastoral land @ 5 arc minute
GDE_in_pastoral = c(gde$GDE_sqm, pasture |> crop(gde$GDE_sqm)) |> 
  as_tibble() |> 
  set_colnames(c("gde_area", "pasture_dens")) |> 
  filter(pasture_dens >= 0.25) |> 
  pull(gde_area) |> 
  sum(na.rm = T)
message(GDE_in_pastoral/1e6 /1e6)
#> 4.903 million km2

GDE_in_pastoral / sum(gde$GDE_sqm[], na.rm = T)
#> 0.5880405
#> 59%




# # Calculate summary statistics
# rcl.mat = c(seq(0, 0.75, by = 0.25,),
#             seq(0.25, 1, by = 0.25),
#             seq(1, 4, by = 1)) |>
#   matrix(ncol = 3)
# rcl.mat[4,2] = Inf
# pst_c = terra::classify(x = pasture, rcl = rcl.mat, include.lowest = T)
# pst_c = terra::crop(pst_c, gde)
# pst_stat = terra::zonal(x = gde, z = pst_c, fun = "sum", na.rm = T)
# pst_stat$pct = round(100*pst_stat$GDE_sqkm / sum(pst_stat$GDE_sqkm), 2)
# pst_stat$pctcs = 100- cumsum(pst_stat$pct)
# pst_stat$GDE_sqkm = pst_stat$GDE_sqkm/1e6
# pst_stat
# 
# gde_c = terra::classify(x = gde, rcl = rcl.mat, include.lowest = T)
# pst_c = terra::classify(x = pasture, rcl = rcl.mat, include.lowest = T)