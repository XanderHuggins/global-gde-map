library(here)
invisible(sapply(paste0(here("R/setup"), "/", list.files(here("R/setup"))), source)) 

# Now import GRACE GWS trends from VIC and NOAH
gws_vic = terra::rast("D:/Geodatabase/GRACE/Hrishi/GRACE_gws_trend/gldas_2.1_vic_local_trends.nc")[[5]]
gws_se_vic = terra::rast("D:/Geodatabase/GRACE/Hrishi/GRACE_gws_trend/gldas_2.1_vic_local_trends.nc")[[10]]

gws_noah = terra::rast("D:/Geodatabase/GRACE/Hrishi/GRACE_gws_trend/gldas_2.1_noah_local_trends.nc")[[5]]
gws_se_noah = terra::rast("D:/Geodatabase/GRACE/Hrishi/GRACE_gws_trend/gldas_2.1_noah_local_trends.nc")[[10]]

ext(gws_vic) = ext(gws_noah) = ext(gws_se_vic) = ext(gws_se_noah) =  c(-180, 180, -90, 90)

gws_mean = mean(c(gws_vic, gws_noah))
gws_se_mean = mean(c(gws_se_vic, gws_se_noah))

# initialize raster to compare storage trends with standard errros
gws_sig = rast(gws_mean)
gws_sig[!is.na(gws_mean)] = 0

# identify cells where drying > magnitude of std error and wetting > magnitude of std error
gws_sig[gws_mean < 0 & abs(gws_mean) > abs(gws_se_mean)] = -1
gws_sig[gws_mean > 0 & abs(gws_mean) > abs(gws_se_mean)] = 1

# list each GDE tile
gde_tiles_f = list.files(path = "D:/Geodatabase/GDEs/GlobalGDE_v5/", full.names = T)
gde_tiles_s = list.files(path = "D:/Geodatabase/GDEs/GlobalGDE_v5/", full.names = F)

for (i in 2:length(gde_tiles_f)) {
  i = 1
  gde_tile_in = terra::rast(gde_tiles_f[i])
  terra::ext(gde_tile_in) = round(terra::ext(gde_tile_in), 0)
  
  
  
  # crop wdpa to tile extent
  gws_tile = terra::crop(x = gws, y = terra::ext(gde_tile_in))
  gws_tile = terra::disagg(x = gws_tile, fact = 1800)
  
  terra::writeRaster(gws_tile,
                     filename = paste0("D:/projects/dryland-GDEs/grace_gws_tiles/", 
                                       gsub(".tif", "_gws.tif", gde_tiles_s[i])),
                     overwrite = T)
  
  print(i); print(round(i/length(wdpa_tiles_s), 2))
  
  gde_tile_in = gws_tile = NULL
  
  terra::tmpFiles(remove=T)
  
}