
############### -
## Convert WDPA vectors to a 1-km raster
############### -

library(here); library(whitebox)
invisible(sapply(paste0(here("R/setup"), "/", list.files(here("R/setup"))), source)) 

# bin 0
whitebox::wbt_vector_polygons_to_raster(input = "D:/Geodatabase/Ecological/WDPA/!2023_June_update/WDPA_Jun2023_Public_shp_0/WDPA_Jun2023_Public_shp-polygons.shp",
                                        output = "D:/Geodatabase/Ecological/WDPA/!2023_June_update/rast_1km_bin0.tif",
                                        field = "PA_DEF",
                                        base = "C:/Users/xande/Documents/2.scripts/global-gw-archetypes/data/ggrid_30arcsec.tif")

# bin 1
whitebox::wbt_vector_polygons_to_raster(input = "D:/Geodatabase/Ecological/WDPA/!2023_June_update/WDPA_Jun2023_Public_shp_1/WDPA_Jun2023_Public_shp-polygons.shp",
                                        output = "D:/Geodatabase/Ecological/WDPA/!2023_June_update/rast_1km_bin1.tif",
                                        field = "PA_DEF",
                                        base = "C:/Users/xande/Documents/2.scripts/global-gw-archetypes/data/ggrid_30arcsec.tif")

# bin 2
whitebox::wbt_vector_polygons_to_raster(input = "D:/Geodatabase/Ecological/WDPA/!2023_June_update/WDPA_Jun2023_Public_shp_2/WDPA_Jun2023_Public_shp-polygons.shp",
                                        output = "D:/Geodatabase/Ecological/WDPA/!2023_June_update/rast_1km_bin2.tif",
                                        field = "PA_DEF",
                                        base = "C:/Users/xande/Documents/2.scripts/global-gw-archetypes/data/ggrid_30arcsec.tif")


# Now merge all rasters and 
wdpa_bins = list.files(path = "D:/Geodatabase/Ecological/WDPA/!2023_June_update/", full.names = T, pattern = "rast_") |> 
  lapply(rast)
wdpa_bins$fun = max
mosaic_set = do.call(terra::mosaic, wdpa_bins)
mosaic_set[mosaic_set>1] = 1

writeRaster(mosaic_set,
            filename = here("data/wdpa_binary_1km.tif"))

# 2/ Rasterize areas with sustainable groundwater mgmt policies (i.e., EU, CA, AUS, SA)
aus = terra::vect("D:/Geodatabase/GDEs/Custom_tile_groups/Protected_status/Australia-administrative-boundary.sqlite")
saf = terra::vect("D:/Geodatabase/GDEs/Custom_tile_groups/Protected_status/SouthAfrica-administrative-boundary2.sqlite")
cal = terra::vect("D:/Geodatabase/GDEs/Custom_tile_groups/Protected_status/California-administrative-boundary.sqlite")
eur = terra::vect("D:/Geodatabase/GDEs/Custom_tile_groups/Protected_status/EU-administrative-boundary.sqlite")

# reimport wdpa raster if running from stage 2 onwards
mosaic_set = terra::rast(here("data/wdpa_binary_1km.tif"))

aus_r = terra::rasterize(x = aus, y = mosaic_set, touches = T)
saf_r = terra::rasterize(x = saf, y = mosaic_set, touches = T)
cal_r = terra::rasterize(x = cal, y = mosaic_set, touches = T)
eur_r = terra::rasterize(x = eur, y = mosaic_set, touches = T)

pol_prot = c(aus_r, saf_r, cal_r, eur_r)
pol_prot = sum(pol_prot, na.rm = T)

writeRaster(pol_prot,
            filename = here("data/pol_protect_1km.tif"))


# Create classification for where WDPA and policy protections co-occur
combined_set = c(mosaic_set, pol_prot) |> sum(na.rm = T)
# combined_set[mosaic_set == 1 & pol_prot == 1] = 3
# combined_set[mosaic_set == 0 & pol_prot == 1] = 2
# combined_set[mosaic_set == 0 & pol_prot == 1] = 2

writeRaster(combined_set,
            filename = here("data/wdpa_and_gw_pol_prot_1km.tif"))