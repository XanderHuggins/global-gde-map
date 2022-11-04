library(here)
invisible(sapply(paste0(here("R/setup"), "/", list.files(here("R/setup"))), source)) 

# create area raster and write for each 

# list each GDE tile
gde_tiles_f = list.files(path = "D:/Geodatabase/GDEs/GlobalGDE_v5/", full.names = T)
gde_tiles_s = list.files(path = "D:/Geodatabase/GDEs/GlobalGDE_v5/", full.names = F)

for (i in 1:length(gde_tiles_f)) {

  gde_tile_in = terra::rast(gde_tiles_f[i])
  terra::ext(gde_tile_in) = round(terra::ext(gde_tile_in), 0)
  
  terra::cellSize(x = gde_tile_in, unit = "km",
                  filename = paste0("D:/projects/dryland-GDEs/area_tiles/", 
                                    gsub(".tif", "_area.tif", gde_tiles_s[i])),
                  overwrite = T)
}
