
############### -
## Calculate overlap of GDEs and protected areas
############### -

library(here)
invisible(sapply(paste0(here("R/setup"), "/", list.files(here("R/setup"))), source)) 

# import GDEs
gdes = terra::rast("D:/Geodatabase/GDEs/00_aggregated_tiles/mosiac_sets/GDE_drylands_30arcsec.tif")

# import PA set
prot = terra::rast(here("data/wdpa_and_gw_pol_prot_1km.tif"))
prot[is.na(prot)] = 0
names(prot) = "prot"
prot = terra::crop(x = prot, y = gdes)

# extract only the GDE area raster
gde_area = gdes[[1]]

# bivar_summ = rasterDT::zonalDT(x = raster(gde_area), z = raster(prot), fun = sum, na.rm = T)
# bivar_summ$GDE_sqkm |> sum()/1e6
# bivar_summ$pct = round(100*bivar_summ$GDE_sqkm / sum(bivar_summ$GDE_sqkm), 2)
# bivar_summ
# 
# write_rds(bivar_summ, file = here("data/gde-in-protected-areas-summary.rds"))
bivar_summ = readr::read_rds(here("data/gde-in-protected-areas-summary.rds"))
bivar_summ/1e6
#>> 1: 0 6.5832423 # GDE not protected
#>> 2: 1 1.5482886 # GDE in either PA or policy
#>> 3: 2 0.2070168 # GDE in both PA and policy

# percent protected (class 2 or 3)
bivar_summ$GDE_sqkm[2:3] |> sum() / bivar_summ$GDE_sqkm[1:3] |> sum()
#>  0.2105049

# area with some protection
bivar_summ$GDE_sqkm[2:3] |> sum()/1e6
#> 1.755305

#### create bivariate legend

## first classify gde density into 3 classes
rcl.m = c(0, 0.05, 1,
          0.05, 0.20, 2,
          0.20, Inf, 3) |> 
  matrix(ncol = 3, byrow = TRUE)

gde_dens = terra::classify(x = gdes[[3]], rcl = rcl.m, include.lowest = T)
plot(gde_dens)

bivar = (prot*10) + gde_dens

writeRaster(bivar, filename = here("data/prot_gdeD_bv_1km_v2.tif"))
