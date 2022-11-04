library(here)
invisible(sapply(paste0(here("R/setup"), "/", list.files(here("R/setup"))), source)) 

# list each GDE tile
gde_tiles_f = list.files(path = "D:/Geodatabase/GDEs/GlobalGDE_v5/", full.names = T)
gde_tiles_s = list.files(path = "D:/Geodatabase/GDEs/GlobalGDE_v5/", full.names = F)

for (i in 22:length(gde_tiles_f)) {
  # i = 5
  gde_tile_in_r  = raster(gde_tiles_f[i])
  gde_tile_in_t  = terra::rast(gde_tiles_f[i])
  raster::extent(gde_tile_in_r) = round(raster::extent(gde_tile_in_r), 0)
  terra::ext(gde_tile_in_t) = round(terra::ext(gde_tile_in_t), 0)
  
  
  # first calculate the area of GDEs within the tile ~45 seconds
  area_tile_in = raster(paste0("D:/projects/dryland-GDEs/area_tiles/", gsub(".tif", "_area.tif", gde_tiles_s[i])))
  gde_area = rasterDT::zonalDT(x = area_tile_in, z = gde_tile_in_r, fun = sum, na.rm = T)
  write_rds(x = gde_area |> as.data.frame() |> set_colnames(c('z', 'area')),
            file = paste0("D:/projects/dryland-GDEs/summary_exports/GDE_area/", 
                          gsub(".tif", "_gde_area.rds", gde_tiles_s[i])))
  message("base gde areas calculated/written")
  
  # now create a tile to represent the combination of FEOW ID and GDE class and calculate surface area of these IDs
  if (file.exists(paste0("D:/projects/dryland-GDEs/feow_tiles/", gsub(".tif", "_feow.tif", gde_tiles_s[i])))) {
    feow_tile_in = raster(paste0("D:/projects/dryland-GDEs/feow_tiles/", gsub(".tif", "_feow.tif", gde_tiles_s[i])))
    feow_gde_id = (terra::rast(feow_tile_in)*1e3) + gde_tile_in_t
    feow_gde_id = raster(feow_gde_id)
    feow_gde_area = rasterDT::zonalDT(x = area_tile_in, z = feow_gde_id, fun = sum, na.rm = T)
    write_rds(x = feow_gde_area |> as.data.frame() |> set_colnames(c('z', 'area')),
              file = paste0("D:/projects/dryland-GDEs/summary_exports/FEOW_GDE_area/", 
                            gsub(".tif", "_feow_gde_area.rds", gde_tiles_s[i])))
    message("feow+gde areas calculated/written")
  }
  
  # now calculate the combination of protected areas class and GDE class and calculate surface area of these IDs
  if (file.exists(paste0("D:/projects/dryland-GDEs/wdpa_raster_tiles/", gsub(".tif", ".tif", gde_tiles_s[i])))) {
    prot_tile_in = raster(paste0("D:/projects/dryland-GDEs/wdpa_raster_tiles/", gsub(".tif", ".tif", gde_tiles_s[i]))) 
    prot_gde_id = (terra::rast(prot_tile_in)*1e3) + gde_tile_in_t
    prot_gde_id = raster(prot_gde_id)
    prot_gde_area = rasterDT::zonalDT(x = area_tile_in, z = prot_gde_id, fun = sum, na.rm = T)
    write_rds(x = prot_gde_area |> as.data.frame() |> set_colnames(c('z', 'area')),
              file = paste0("D:/projects/dryland-GDEs/summary_exports/PROT_GDE_area/", 
                            gsub(".tif", "_prot_gde_area.rds", gde_tiles_s[i])))
    message("prot+gde areas calculated/written")
  }
  
  # now calculate the area distribution of groundwater storage trends in 
  if (file.exists(paste0("D:/projects/dryland-GDEs/grace_gws_tiles/", gsub(".tif", "_gws.tif", gde_tiles_s[i])))) {
    gwst_tile_in = raster(paste0("D:/projects/dryland-GDEs/grace_gws_tiles/", gsub(".tif", "_gws.tif", gde_tiles_s[i])))
    
    gws_rcl = data.frame(low  = seq(-0.1, 0.1-0.005, by = 0.005),
                         high = seq(-0.1+0.005, 0.1, by = 0.005),
                         new  = seq(1, 40, length.out = 40)) |> 
      as.matrix()
    
    gwst_tile_rcl = terra::classify(x = terra::rast(gwst_tile_in), rcl = gws_rcl, include.lowest = T)
    gws_gde_id = gwst_tile_rcl*1e3 + gde_tile_in_t
    gws_gde_id = raster(gws_gde_id)
    gws_gde_area = rasterDT::zonalDT(x = area_tile_in, z = gws_gde_id, fun = sum, na.rm = T)
    write_rds(x = gws_gde_area |> as.data.frame() |> set_colnames(c('z', 'area')),
              file = paste0("D:/projects/dryland-GDEs/summary_exports/GWS_GDE_area/", 
                            gsub(".tif", "_gws_gde_area.rds", gde_tiles_s[i])))
    message("gws+gde areas calculated/written")
  }
  
  message("tile ", i, " is complete! ")
  tmpFiles(current=TRUE, remove=TRUE) # remove the temporary files produced
}