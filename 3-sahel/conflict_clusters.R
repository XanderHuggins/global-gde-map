# Get conflict clusters based on 0.5deg hex grid

# Setup
library(ggplot2)
library(dplyr)
library(raster)
library(sf)
library(exactextractr)
library(tictoc)
library(terra)
library(dbscan)
options(dplyr.summarise.inform = FALSE)
root <- "C:/Users/marya/Dropbox/gwflagship_gde_tnc"
setwd(root)

#-------------------------------------------------------------------------------
# GREATER SAHEL HEX GRID
#-------------------------------------------------------------------------------
# Overlap bbox hex grid (created in QGIS) w/ greater Sahel to get only 
# overlapping cells
gs <- st_read('data/~raw/admin/greater_sahel')
hx <- st_read('data/base_grids/hex05deg_greater_sahel_bbox') 
hx_oix <- hx %>%
  st_intersects(gs) %>%
  lengths > 0
hxo <- hx %>% filter(hx_oix)
hxo$hexid = hxo$id
ggplot() + geom_sf(data=hxo, aes(geometry=geometry))


#-------------------------------------------------------------------------------
# DATA INTERSECTIONS
#-------------------------------------------------------------------------------
## ACLED (counts)
load = TRUE
cache <- 'data/~cache/hex05deg_gs_acled.rda'
if (file.exists(cache) & load) {
  aclo_a <-readRDS(file=cache)
} else {
  acl <- st_read('data/~raw/acled_africa/acled_africa.shp')
  hx_aclo <- st_intersects(hxo,acl)
  aclo_a <-  hx_aclo %>% lengths %>% as.data.frame()
  names(aclo_a) <- c("acld_cnt")
  aclo_a$hexid <- hxo$hexid
  saveRDS(aclo_a,file=cache)
}


## TNC-GDE
load = TRUE
cache_f <- 'data/~cache/hex05deg_gs_tnc_gde'
cache <- paste0(cache_f,'.rda')
if (file.exists(cache) & load) {
  gde_a <-readRDS(file=cache)
} else {
  ### Read in tile-index & find tiles which intersect w/ hxo
  # Make sure this index has filepaths for your computer. If not, delete the files in the folder and rerun the python script to create this.
  tnc_ix <- st_read('data/tnc_gde/tile_index/tile_index.shp')
  tnc_ox <- tnc_ix %>%
    st_intersects(hxo) %>%
    lengths > 0
  tnc_ixo <- tnc_ix %>% filter(tnc_ox)
  ggplot() + 
    geom_sf(data=hxo, aes(geometry=geometry)) +
    geom_sf(data=tnc_ixo, aes(geometry=geometry), fill=NA, color="red")
  
  r1 <- raster(tnc_ixo$location[1])
  hxo_t <- st_transform(hxo,crs(r1))
  #levels(r1) <- list(data.frame(ID = c(0,1,2) ,gde = c("na","isgde","isnotgde")))
  

  ### Loop through tiles and find overlap
  tload = TRUE
  olap <- function(tilepath){
    print(tilepath)
    cachet <- basename(tilepath) %>% {paste0(cache_f,'/',gsub(".tif", ".rda", .))}
    
    if (file.exists(cachet) & tload) {
      print("Loading from file")
      return(readRDS(file=cachet))
    }
    
    # Process tile
    r <- rast(tilepath) %>% classify(cbind(1, 2, 0), right=TRUE)
    ol<- exact_extract(r, hxo_t, c('min','max','count','sum')) %>%
      mutate(hexid=hxo$hexid) %>%
      filter(count>0)
    
    # Save to temp cache
    ol %>% saveRDS(file=cachet)
    gc()
    return(ol)
  }
  
  
  tic()
  gde<-do.call(rbind, lapply(tnc_ixo$location, olap)) ## 1461.37 sec elapsed
  toc()
 
  
  gde_a <- gde %>%
           group_by(hexid) %>%
           summarize(gde_cnt_true=sum(sum), gde_cnt_all=sum(count))
  
  # Save to cache
  gde_a %>% saveRDS(file=cache)
}


#-------------------------------------------------------------------------------
# COMBINE, FLAG
#-------------------------------------------------------------------------------

## Combine
hxo$area <- st_area(st_transform(hxo, st_crs("ESRI:54009")))
hxo_all <- hxo %>% left_join(aclo_a, by = 'hexid') %>% 
  left_join(gde_a, by = 'hexid')
hxo_all[is.na(hxo_all)] <- 0

## GDE flags
hxo_all <- hxo_all %>% 
  mutate(gde_pct_area = (gde_cnt_true*30)/area) %>%
  mutate(gde_pct_pxls = gde_cnt_true/gde_cnt_all) %>%
  mutate(acld_by_area=acld_cnt/area)

hxo_all <- hxo_all %>% 
  mutate(flag_gde=gde_pct_pxls>quantile(gde_pct_pxls,c(.75)),
  flag_gde_area = gde_pct_area>quantile(gde_pct_area,c(.75)),
  flag_acld=acld_by_area>quantile(acld_by_area,c(.9)))

hxo_all <- hxo_all %>% 
  mutate(flag_clstr=flag_acld&flag_gde_area)

#-------------------------------------------------------------------------------
# CLUSTER
#-------------------------------------------------------------------------------

## Find clusters of flagged hexagons
hex_flagged <- hxo_all %>% filter(flag_clstr)
xy <- st_centroid(hex_flagged)[,c("geometry","hexid")]
xy_coords <- xy %>% st_coordinates()
hex_flagged$cid <- dbscan(xy_coords, eps = 2, minPts = 4) %>% 
  pluck('cluster')

## Dissolve and form convex hull boundaries around clusters
cls <- hex_flagged %>% 
  filter(cid>0) %>% 
  group_by(cid) %>%
  summarize(geometry = st_union(geometry)) %>%
  st_convex_hull

## Intersect w/ Hex & take 50% or more of polygon as inclusive
#hx_cls <- st_intersects(hxo,cls)
#hxo_all$cid <- apply(hx_cls, 1, function(d) {cls[which(d), ]$cid[1]})
hxo_all_cls <- hxo_all %>% st_intersection(cls) %>% 
  mutate(cid_pct_area = as.numeric(st_area(st_transform(.,st_crs("ESRI:54009"))) / area)) %>%
  as.data.frame() %>%
  subset(select=c('hexid', 'cid', 'cid_pct_area')) %>%
  {left_join(hxo_all,., by="hexid")}


## Cluster outlines
hxo_cls <- hxo_all_cls %>% 
  filter(cid>0 & cid_pct_area>.5) %>% 
  st_buffer(0) %>% # prevents weird lines
  group_by(cid) %>%
  summarize(geometry = st_union(geometry))

ggplot() + 
  geom_sf(data=hxo_all, aes(geometry=geometry, fill=flag_gde_area)) +
  scale_fill_manual(values=c("white","red")) +
  geom_sf(data=hxo_all, aes(geometry=geometry, color=flag_acld), fill=NA) +
  scale_color_manual(values=c("white","blue")) +
 #geom_sf(data=filter(hxo_all,flag_clstr), aes(geometry=geometry), color="yellow") +
  geom_sf(data=hxo_cls, aes(geometry=geometry), fill="orange", color="yellow", lwd=1.5) +
  geom_sf(data=filter(hex_flagged, cid>0), aes(geometry=geometry), fill="green") +
  geom_sf(data=cls, aes(geometry=geometry), fill=NA,color="hotpink")

#-------------------------------------------------------------------------------
# SAVE OUT
#-------------------------------------------------------------------------------
hxo_all %>% st_write(dsn='data/final_grids/hex05deg_greater_sahel.geojson', delete_dsn=TRUE)
hxo_cls %>% st_write('data/final_grids/hex05deg_greater_sahel_clusters.geojson', delete_dsn=TRUE)
  