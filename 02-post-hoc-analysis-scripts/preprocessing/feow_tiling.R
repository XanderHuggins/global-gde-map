library(here)
invisible(sapply(paste0(here("R/setup"), "/", list.files(here("R/setup"))), source)) 

# rasterize the freshwater ecoregions of the world (feow) for each tile at 30m

# list each GDE tile
gde_tiles_f = list.files(path = "D:/Geodatabase/GDEs/GlobalGDE_v5/", full.names = T)
gde_tiles_s = list.files(path = "D:/Geodatabase/GDEs/GlobalGDE_v5/", full.names = F)

# import feow
feow = terra::vect("D:/Geodatabase/Ecological/Ecoregions/Freshwater/feow_hydrosheds.shp")

for (i in 21:length(gde_tiles_f)) {
  # i = 20
  gde_tile_in = terra::rast(gde_tiles_f[i])
  terra::ext(gde_tile_in) = round(terra::ext(gde_tile_in), 0)
  
  # crop wdpa to tile extent
  feow_tilecrop = terra::crop(x = feow, y = terra::ext(gde_tile_in))
  
  feow_tile_sf = st_as_sf(feow_tilecrop) |> st_cast(to = "MULTIPOLYGON")
  feow_tile_r = fasterizeDT(x = feow_tile_sf, raster = raster(gde_tile_in), 
                            field = 'FEOW_ID', fun = 'last')
  feow_tile_r = terra::rast(feow_tile_r)
  
  terra::ext(feow_tile_r) = round(terra::ext(gde_tile_in), 0)
  
  terra::writeRaster(feow_tile_r,
                     filename = paste0("D:/projects/dryland-GDEs/feow_tiles/", 
                                       gsub(".tif", "_feow.tif", gde_tiles_s[i])),
                     filetype = "GTiff",
                     overwrite = T)
  
  gde_tile_in = feow_tilecrop = feow_tile_sf = feow_tile_r = NULL
  
  print(i); print(round(i/length(gde_tiles_s), 2))
  
  terra::tmpFiles(remove=T)
  
}
