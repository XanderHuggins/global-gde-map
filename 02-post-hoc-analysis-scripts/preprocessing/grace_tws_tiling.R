library(here)
invisible(sapply(paste0(here("R/setup"), "/", list.files(here("R/setup"))), source)) 

# import the GRACE gws storage trend raster
gws = terra::rast("D:/Geodatabase/GRACE/Hrishi/gws_trend_mean.tif")

# list each GDE tile
gde_tiles_f = list.files(path = "D:/Geodatabase/GDEs/GlobalGDE_v5/", full.names = T)
gde_tiles_s = list.files(path = "D:/Geodatabase/GDEs/GlobalGDE_v5/", full.names = F)

for (i in 2:length(gde_tiles_f)) {
  # i = 1
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
