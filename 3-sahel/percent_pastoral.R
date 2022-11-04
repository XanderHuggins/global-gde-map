# Calculate % pastoral GDEs

# Setup
library(ggplot2)
library(dplyr)
library(raster)
library(sf)
library(exactextractr)
library(tictoc)
options(dplyr.summarise.inform = FALSE)
root <- "C:/Users/marya/Dropbox/gwflagship_gde_tnc"
setwd(root)


# Extracts zonal statistics from rasters
raster2poly <- function(raster, poly, pfix="", polyid="OBJECTID") {
  tic()
  # Extract raster values by polygons
  rvals <- exact_extract(raster,
                         st_transform(poly,crs(raster)), 
                         c('mean','min','max','median','stdev','count','sum','mode')
  )
  toc()
  
  # Rename raster2poly values
  ids <- poly[[polyid]] %>% as.data.frame()
  rvals2 <- cbind(ids,rvals)
  names <- names(rvals2) %>% .[2:length(.)]
  new_names <- c(polyid, sapply(names, function(x) paste0(pfix,"_",x)))
  names(rvals2) <- new_names
  
  return(rvals2)
}

#-------------------------------------------------------------------------------
# LOAD FISHNET GRID and ADD GREATER SAHEL FLAG
#-------------------------------------------------------------------------------
cache <- 'data/~cache/grid05deg.gpkg'
if (file.exists(cache)) {
  gd <- st_read(file.path(cache))
} else {

  ## Load grid and make valid
  gd <- st_read('data/base_grids/grid05deg/grid05deg.shp') %>% st_make_valid
  
  ## Mollweide area
  gd$area <- st_area(st_transform(gd, st_crs("ESRI:54009")))
  
  ## Greater Sahel flag
  gs <- st_read('data/~raw/admin/greater_sahel/greater_sahel.shp')
  sf::sf_use_s2(FALSE) # Don't check spherical for grid
  gd_o <- st_transform(gd,st_crs("ESRI:54009")) %>% st_intersects(st_transform(gs,st_crs("ESRI:54009"))) %>% lengths > 0
  gd[gd_o,"flag_greater_sahel"]=1
  ggplot() +geom_sf(data=filter(gd,flag_greater_sahel==1),aes(geometry=geometry))
  st_write(gd,cache, append=FALSE)
}

#-------------------------------------------------------------------------------
# DATA INTERSECTIONS
#-------------------------------------------------------------------------------

## TNC-GDE
cache_f <- 'data/~cache/grid05deg_tnc_gde'
cache <- paste0(cache_f,'.rda')
if (file.exists(cache)) {
  gd_gde <-readRDS(file=cache)
} else {

  ### Read in tile-index and create grid-tile index
  tnc_ix <- st_read('data/tnc_gde/tile_index/tile_index.shp')
  tcrs <- crs(raster(tnc_ix$location[1]))
  gd_t <- st_transform(gd,tcrs) ## Make sure grid is in raster format
  tiles <- tnc_ix$location
  print(sprintf('Length of tiles is %s', length(tiles)))
  cache_tix <- paste0(cache_f,"/tile_gid.rda")
  if (file.exists(cache_tix)) {
    print("Loading tile_gid from file")
    tile_gid <-readRDS(file=cache_tix)
  } else {
    print("Making tile_gid")
    sf::sf_use_s2(FALSE) # Don't check spherical for grid
    tile_gid <- st_intersects(st_transform(tnc_ix, tcrs), gd_t)
    crs.mw <- st_crs("ESRI:54009")
    tile_gid<-st_intersects(st_transform(tnc_ix, crs.mw), st_transform(gd,crs.mw))
    saveRDS(tile_gid, file=cache_tix)
  }
  
  ### Loop through tiles and find overlap
  olap <- function(ti, tiles, tile_gid, gd_t,cache_f){
    
    print(sprintf('%s: (%s%%...)', ti, round(ti/length(tiles)*100,0)))
    
    tilepath <- tiles[[ti]]
    print(sprintf('%s: %s',ti,tilepath))
    cachet <- basename(tilepath) %>% {paste0(cache_f,'/',gsub(".tif", ".rda", .))}
    
    if (file.exists(cachet)) {
      print(sprintf('%s: Loading from file',ti))
      return(readRDS(file=cachet))
    }
    
    # Subset grid cells that overlap
    gd_s <- gd_t[tile_gid[[ti]],]
    if(nrow(gd_s)==0) {
      print(sprintf('%s: GDS is 0',ti))
      ol<-data.frame(matrix(ncol = 2, nrow = 0))
      names(ol) <- c('sum', 'OBJECTID')
    } else {
      # Process tile
      print(sprintf('%s: Processing tile',ti))
      r <- raster(tilepath)
      NAvalue(r) <- 2
      ol<- exact_extract(r, gd_s, c('sum'), progress = FALSE) %>%
        as.data.frame() %>%
        mutate(OBJECTID=gd_s$OBJECTID)
      names(ol) <- c('sum', 'OBJECTID')
    }
    # Save to temp cache
    print(sprintf('%s: Saving tile',ti))
    ol %>% saveRDS(file=cachet)
    gc() # cleans up
    return(ol)
  }
  gde_l <- lapply(1:length(tiles),olap,tiles,tile_gid,gd_t,cache_f)
 
  
  ### Combine results
  gd_gde <- bind_rows(gde_l) %>%
    group_by(OBJECTID) %>%
    summarize(gde_cnt_true=sum(sum))
  
  # Save to cache
  gd_gde %>% saveRDS(file=cache)
}


## RAMANKUTTY
cache <- 'data/~cache/grid05deg_ramankutty.rda'
if (file.exists(cache)) {
  gd_past <-readRDS(file=cache)
} else {
  r<-raster('data/ramankutty_pasture_nodata_to_0/pasture_nodata_to_0/gl_pasture_0.tif')
  gd_past <- raster2poly(r,gd,pfix="pasture_", polyid="OBJECTID")
  gd_past %>% saveRDS(file=cache)
}


#-------------------------------------------------------------------------------
# COMBINE, PRINT OUT
#-------------------------------------------------------------------------------

## Combine
gd_all <- gd %>% left_join(gd_gde, by = 'OBJECTID') %>% 
  left_join(gd_past, by = 'OBJECTID')
gd_all[is.na(gd_all)] <- 0


## Mean Pasture?
pst.mean <- mean(gd_all$pasture__mean)
sprintf("Mean pasture: %s", round(pst.mean*100,1))
gd_all <- gd_all %>% 
  mutate(flag_pastoral = gd_all$pasture__mean>.16)

## % GDEs in pastoral lands (w/ flag=16)
pastoral_gde <- function(data) {
  total.gde <- sum(data$gde_cnt_true)
  total.area <- sum(data$area)
  by_pastoral <- data  %>% 
    group_by(flag_pastoral) %>% 
    summarize(gde=sum(gde_cnt_true), 
              area=sum(area))
  by_pastoral <-by_pastoral %>% 
    mutate(gde_km2=gde*30/1000000, 
           gde_pct=gde/total.gde,
           pastoral_pct=area/total.area)
  return(by_pastoral[2,])
}

### SAHEL
x <- gd_all %>% 
  as.data.frame %>% 
  filter(flag_greater_sahel==1) %>% 
  pastoral_gde
sprintf("In the Greater Sahel, %s%% of GDEs (%s km2) exist on pastoral lands which make up %s%% of the landscape.", 
        round(x$gde_pct*100,1), 
        format(round(x$gde_km2,0),big.mark=","),
        round(x$pastoral_pct*100,1)
       )

### GLOBALLY
x <- gd_all %>% 
  as.data.frame %>% 
  pastoral_gde
sprintf("Globally, %s%% of GDEs (%s km2) exist within pastoral lands.", 
        round(x$gde_pct*100,1), 
        format(round(x$gde_km2,0),big.mark=",")
)
