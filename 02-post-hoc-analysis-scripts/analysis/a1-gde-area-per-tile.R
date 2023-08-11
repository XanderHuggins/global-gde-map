
######################################### -
## Calculate GDE area per tile 
######################################### -

# load dependencies
library(here)
invisible(sapply(paste0(here("R/setup"), "/", list.files(here("R/setup"))), source)) 

# load individual tile file paths
gde_tiles_f = list.files(path = "D:/Geodatabase/GDEs/v6_tiles/", full.names = T) # full path name 
gde_tiles_s = list.files(path = "D:/Geodatabase/GDEs/v6_tiles/", full.names = F) # short path name


##### - loop through all tiles

## start based on number of tiles already completed
st_no = length(list.files(path="D:/Geodatabase/GDEs/00_aggregated_tiles/30arcmin/"))  + 1

for (i in st_no:length(gde_tiles_f)) {
  
  message("beginning tile no. ", i)
  st = Sys.time()
  
  # import GDE tile
  gde_tile = rast(gde_tiles_f[i])
  gde_tile = gde_tile[[1]] # keep only first layer as is the classification layer
  
  ############### READ ME
  ## RASTER VALUES
  ## 2 : not likely GDE 
  ## 1 : likely GDE
  ## 0 : not analyzed 
  ############### end readme
  
  # import cell grid area tile
  area_tile = rast(paste0("D:/projects/dryland-GDEs/area_tiles/", gsub(".tif", "_area.tif", gde_tiles_s[i])))
  
  # snap the GDE tile to the grid-area tile
  ext(gde_tile) = ext(area_tile)
  
  # create a binary map of (1) GDE area, (2) analyzed area [ANL], and (3) all area [ALL]
  gde_bin = terra::classify(x = gde_tile,
                            rcl = data.frame(from = c(2), 
                                             to   = c(0)) |> as.matrix())
  
  anl_bin = terra::classify(x = gde_tile,
                            rcl = data.frame(from = c(2), 
                                             to   = c(1)) |> as.matrix())
  
  # now convert these binary rasters to areas
  gde_area = terra::mask(x = area_tile,
                         mask = gde_bin,
                         maskvalues = 0)
  
  anl_area = terra::mask(x = area_tile,
                         mask = anl_bin,
                         maskvalues = 0)
  
  
  ######-
  # summarize to 30 arcsecond, 5 arcminute, and 30 arcminute resolutions
  
  ## gde area
  gde_area_30arcsec = terra::aggregate(x = gde_area, fact = 30/1, fun = "sum", na.rm = T, cores = 7)
  gde_area_05arcmin = terra::aggregate(x = gde_area_30arcsec, fact = 5/0.5, fun = "sum", na.rm = T, cores = 7)
  gde_area_30arcmin = terra::aggregate(x = gde_area_05arcmin, fact = 30/5, fun = "sum", na.rm = T, cores = 7)
  
  
  ## analysed area
  anl_area_30arcsec = terra::aggregate(x = anl_area, fact = 30/1, fun = "sum", na.rm = T, cores = 7)
  anl_area_05arcmin = terra::aggregate(x = anl_area_30arcsec, fact = 5/0.5, fun = "sum", na.rm = T, cores = 7)
  anl_area_30arcmin = terra::aggregate(x = anl_area_05arcmin, fact = 30/5, fun = "sum", na.rm = T, cores = 7)
  
  ## all area
  all_area_30arcsec = terra::aggregate(x = area_tile, fact = 30/1, fun = "sum", na.rm = T, cores = 7)
  all_area_05arcmin = terra::aggregate(x = all_area_30arcsec, fact = 5/0.5, fun = "sum", na.rm = T, cores = 7)
  all_area_30arcmin = terra::aggregate(x = all_area_05arcmin, fact = 30/5, fun = "sum", na.rm = T, cores = 7)
  
  
  ######-
  # calculate densities at 30 arcsecond and 5 arcminute
  
  ## 30 arcsecond
  gde_to_anl_30arcsec = gde_area_30arcsec / anl_area_30arcsec
  gde_to_all_30arcsec = gde_area_30arcsec / all_area_30arcsec
  
  ## 5 arcmniute
  gde_to_anl_05arcmin = gde_area_05arcmin / anl_area_05arcmin
  gde_to_all_05arcmin = gde_area_05arcmin / all_area_05arcmin
  
  ## 30 arcminute
  gde_to_anl_30arcmin = gde_area_30arcmin / anl_area_30arcmin
  gde_to_all_30arcmin = gde_area_30arcmin / all_area_30arcmin
  
  # percent of area analysed
  anl_to_all_30arcsec = anl_area_30arcsec / all_area_30arcsec
  anl_to_all_05arcmin = anl_area_05arcmin / all_area_05arcmin
  anl_to_all_30arcmin = anl_area_30arcmin / all_area_30arcmin
  
  ######-
  # create raster stacks at each resolution
  
  ## 30 arcsecond
  stack_30arcsec = c(gde_area_30arcsec, gde_to_anl_30arcsec, gde_to_all_30arcsec, 
                     anl_area_30arcsec, anl_to_all_30arcsec)
  names(stack_30arcsec) = c('GDE_sqkm', 'GDE_pct_AA', 'GDE_pct_GA',
                            'AA_sqkm', 'AA_pct_GA')
  
  
  ## 5 arcminute
  stack_05arcmin = c(gde_area_05arcmin, gde_to_anl_05arcmin, gde_to_all_05arcmin, 
                     anl_area_05arcmin, anl_to_all_05arcmin)
  names(stack_05arcmin) = c('GDE_sqkm', 'GDE_pct_AA', 'GDE_pct_GA',
                            'AA_sqkm', 'AA_pct_GA')
  
  ## 30 arcminute
  stack_30arcmin = c(gde_area_30arcmin, gde_to_anl_30arcmin, gde_to_all_30arcmin, 
                     anl_area_30arcmin, anl_to_all_30arcmin)
  names(stack_30arcmin) = c('GDE_sqkm', 'GDE_pct_AA', 'GDE_pct_GA',
                            'AA_sqkm', 'AA_pct_GA')
  
  
  ######-
  # write to file 
  terra::writeRaster(x = stack_30arcsec,
                     filename = paste0("D:/Geodatabase/GDEs/00_aggregated_tiles/30arcsec/", 
                                       gsub(".tif", "_30arcsec.tif", gde_tiles_s[i])),
                     overwrite = T)
  
  terra::writeRaster(x = stack_05arcmin,
                     filename = paste0("D:/Geodatabase/GDEs/00_aggregated_tiles/05arcmin/", 
                                       gsub(".tif", "_05arcmin.tif", gde_tiles_s[i])),
                     overwrite = T)
  
  terra::writeRaster(x = stack_30arcmin,
                     filename = paste0("D:/Geodatabase/GDEs/00_aggregated_tiles/30arcmin/", 
                                       gsub(".tif", "_30arcmin.tif", gde_tiles_s[i])),
                     overwrite = T)
  
  et = Sys.time()
  message("tile completed in ", et-st)
  terra::tmpFiles(remove=TRUE)
}



##### - mosaic all tiles together

## 30 arcmin
tiles_30arcmin = list.files(path = "D:/Geodatabase/GDEs/00_aggregated_tiles/30arcmin/", full.names = T, pattern = ".tif") |> 
  lapply(rast)
tiles_30arcmin$fun = max
mosaic_set = do.call(terra::mosaic, tiles_30arcmin)
plot(mosaic_set)

writeRaster(x = mosaic_set,
            filename = "D:/Geodatabase/GDEs/00_aggregated_tiles/mosiac_sets/GDE_drylands_30arcmin.tif",
            overwrite = T)

## 05 arcmin
tiles_05arcmin = list.files(path = "D:/Geodatabase/GDEs/00_aggregated_tiles/05arcmin/", full.names = T, pattern = ".tif") |> 
  lapply(rast)
tiles_05arcmin$fun = max
mosaic_set = do.call(terra::mosaic, tiles_05arcmin)
plot(mosaic_set)

writeRaster(x = mosaic_set,
            filename = "D:/Geodatabase/GDEs/00_aggregated_tiles/mosiac_sets/GDE_drylands_05arcmin.tif",
            overwrite = T)

## 30 arcsec
tiles_30arcsec = list.files(path = "D:/Geodatabase/GDEs/00_aggregated_tiles/30arcsec/", full.names = T, pattern = ".tif") |> 
  lapply(rast)
tiles_30arcsec$fun = max
mosaic_set = do.call(terra::mosaic, tiles_30arcsec)
plot(mosaic_set)

writeRaster(x = mosaic_set,
            filename = "D:/Geodatabase/GDEs/00_aggregated_tiles/mosiac_sets/GDE_drylands_30arcsec.tif",
            overwrite = T)