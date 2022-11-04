library(here)
invisible(sapply(paste0(here("R/setup"), "/", list.files(here("R/setup"))), source)) 

# list each GDE tile
gde_tiles_f = list.files(path = "D:/Geodatabase/GDEs/GlobalGDE_v5/", full.names = T)
gde_tiles_s = list.files(path = "D:/Geodatabase/GDEs/GlobalGDE_v5/", full.names = F)

for (i in 15:length(gde_tiles_f)) {
  gde_tile_in_t  = terra::rast(gde_tiles_f[i])
  terra::ext(gde_tile_in_t) = round(terra::ext(gde_tile_in_t), 0)
  
  if (file.exists(paste0("D:/projects/dryland-GDEs/wdpa_raster_tiles/", gsub(".tif", ".tif", gde_tiles_s[i])))) {
    prot_tile_in = terra::rast(paste0("D:/projects/dryland-GDEs/wdpa_raster_tiles/", gsub(".tif", ".tif", gde_tiles_s[i]))) 
    # prot_tile_in[is.na(prot_tile_in)] = 0
    prot_gde_id = prot_tile_in*1e3 + gde_tile_in_t
    
    terra::writeRaster(prot_gde_id,
                       filename = paste0("D:/projects/dryland-GDEs/wdpa_x_gde_plot_tiles/", 
                                         gsub(".tif", "_gde_pa.tif", gde_tiles_s[i])),
                       overwrite = T)
  }
}