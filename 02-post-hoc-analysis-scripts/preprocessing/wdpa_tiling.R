library(here)
invisible(sapply(paste0(here("R/setup"), "/", list.files(here("R/setup"))), source)) 

# rasterize the WDPA for each tile at 30m

# list each GDE tile
gde_tiles_f = list.files(path = "D:/Geodatabase/GDEs/GlobalGDE_v5/", full.names = T)
gde_tiles_s = list.files(path = "D:/Geodatabase/GDEs/GlobalGDE_v5/", full.names = F)

# import WDPA
wdpa1 = terra::vect("D:/Geodatabase/Ecological/WDPA/Extracted_1/WDPA_Jun2021_Public_shp-polygons.shp")
wdpa2 = terra::vect("D:/Geodatabase/Ecological/WDPA/Extracted_2/WDPA_Jun2021_Public_shp-polygons.shp")
wdpa3 = terra::vect("D:/Geodatabase/Ecological/WDPA/Extracted_3/WDPA_Jun2021_Public_shp-polygons.shp")

for (i in 1:length(gde_tiles_f)) {
  # i = 1
  gde_tile_in = terra::rast(gde_tiles_f[i])
  terra::ext(gde_tile_in) = round(terra::ext(gde_tile_in), 0)
  
  # crop wdpa to tile extent
  wdpa1_tilecrop = terra::crop(x = wdpa1, y = terra::ext(gde_tile_in))
  wdpa2_tilecrop = terra::crop(x = wdpa2, y = terra::ext(gde_tile_in))
  wdpa3_tilecrop = terra::crop(x = wdpa3, y = terra::ext(gde_tile_in))
  
  wdpa_tilecomb = rbind(wdpa1_tilecrop, wdpa2_tilecrop, wdpa3_tilecrop)
  
  terra::writeVector(x = wdpa_tilecomb,
                     filename = paste0("D:/projects/dryland-GDEs/wdpa_vector_tiles/",
                                       gsub(".tif", ".sqlite", gde_tiles_s[i])),
                     filetype = "SQLite",
                     overwrite = T)
  
  gde_tile_in = wdpa1_tilecrop = wdpa2_tilecrop = wdpa3_tilecrop = wdpa_tilecomb = NULL
  
  print(i); print(round(i/length(gde_tiles_s), 2))
  
}

wdpa_tiles_f = list.files(path = "D:/projects/dryland-GDEs/wdpa_vector_tiles/", full.names = T)
wdpa_tiles_s = list.files(path = "D:/projects/dryland-GDEs/wdpa_vector_tiles/", full.names = F)

high_classes = c('Ia', 'Ib', 'II', 'III', 'Not Assigned', 'Not Reported')
low_classes = c('IV', 'V', 'VI', 'Not Applicable')

for (i in 371:length(wdpa_tiles_f)) {
  i = 379
  wdpa_tiles_f[i]
  
  wdpa_tile = terra::vect(wdpa_tiles_f[i])
  
  wdpa_tile$val = rep(NA)
  wdpa_tile$val[wdpa_tile$iucn_cat %in% high_classes] = 1
  wdpa_tile$val[wdpa_tile$iucn_cat %in% low_classes] = 2
  
  tif_temp = terra::rast(paste0("D:/Geodatabase/GDEs/GlobalGDE_v5/", gsub(".sqlite", ".tif", wdpa_tiles_s[i])))
  terra::ext(tif_temp) = round(terra::ext(tif_temp), 0)
  
  wdpa_tile_sf = st_as_sf(wdpa_tile) |> st_cast(to = "MULTIPOLYGON")
  wdpa_tile_r = fasterizeDT(x = wdpa_tile_sf, raster = raster(tif_temp), field = 'val', fun = "min")
  # wdpa_tile_r = terra::rast(wdpa_tile_r)
  # wdpa_tile_r[wdpa_tile_r == 0] = NA
  # terra::ext(wdpa_tile_r) = round(terra::ext(wdpa_tile_r), 0)
  
  raster::writeRaster(wdpa_tile_r,
                      filename = paste0("D:/projects/dryland-GDEs/wdpa_raster_tiles/", 
                                        gsub(".sqlite", ".tif", wdpa_tiles_s[i])),
                      overwrite = T)
  
  # terra::writeRaster(wdpa_tile_r,
  #                    filename = paste0("D:/projects/dryland-GDEs/wdpa_raster_tiles/", 
  #                                      gsub(".sqlite", ".tif", wdpa_tiles_s[i])),
  #                    overwrite = T)
  
  print(i); print(round(i/length(wdpa_tiles_s), 2))
}
