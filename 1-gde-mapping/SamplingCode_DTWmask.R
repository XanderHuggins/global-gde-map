######################################
# Title: SamplingCode_DTWmask
# Description: Training Sample Extraction from Polygons code for Global GDE Mapping
# Author: Christine Albano
# Last Modified: Nov 3, 2022
######################################


library(sf) 
library(tidyverse)
library(maps)
library(raster)
library(fasterize)
library(exactextractr)
library(rgdal)


##### sampling function - inputs are state/country/etc boundary and shapefiles of GDE polygons to sample from and 
##### gde polygons to exclude when generating non-gde sample

trainingsample<-function(area, gdeshape, gdeshapemask){
  
  ## get total area of GDEs in m^2 and convert to km^2
  GDEarea_sqkm<-as.vector(sum(st_area(gdeshape))/1000000)
  
  # set sample size as one point per 10 sqkm area
  sampsize<-round(GDEarea_sqkm/10,0)
  
  #convert gde shapefiles to lat long projection
  gdeshapeprj<-st_transform(gdeshape,crs=latlongprj)
  gdeshapemaskprj<-st_transform(gdeshapemask,crs=latlongprj)
  
  #get DTW for each polygon and filter those with ave DTW greater than 30 m
  # gdeshapeprj<-cbind(gdeshapeprj, exact_extract(dtw, gdeshapeprj, c('mean')))
  gdeshapeprjdtws<-exact_extract(dtw, gdeshapeprj, c('mean'))
  gdeshapeprj$dtw<-gdeshapeprjdtws
  gdeshapeprjDTW30<-gdeshapeprj[which(gdeshapeprj$dtw >= - 30), ]
  
  #get GDE sample
  set.seed(1234)
  GDE_trainsamp<-st_as_sf(st_sample(gdeshapeprjDTW30, sampsize))
  
  #define class as GDE=1, non-GDE = 0
  GDE_trainsamp$class<-rep(1, sampsize)
  
  ####rasterize state and gde shape data as workaround from invalid geometry issues of GDE shapefiles
  
  # add class field to make raster value
  gdeshapemaskprj$class<-1
  
  #make GDE raster using state extent as template
  # this should be fine since For polygons, values are transferred if the polygon covers the center of a raster cell.
  # and fasterize is same method as rasterize https://rdrr.io/cran/raster/man/rasterize.html
  
  # convert state boundary to raster 
  #convert to raster and make values less than 30m DTW = 1
  #use lat-long for states
  areaprj<-st_transform(area,crs=latlongprj)
  arearas<-crop(dtw, areaprj)
  arearas[arearas < -30] <- 1
  
  #raster for non-gde sample
  rgdemask<-fasterize(gdeshapemaskprj, arearas, field="class", fun="min")
  
  #make non-GDE (i.e., NA values) = 0
  rgdemask[is.na(rgdemask[])] <- 0 
  #make places with DTW> 30 NA
  rgdemask[arearas==1] <- NA
  rgdemask[is.na(arearas[])] <- NA
  
  # generate random sample of cells based on sample size (using *1.5 of GDE since many non-GDE may be masked out
  # based on land cover)
  sampsize2<- runif(sampsize*1.5, 1,ncell(rgdemask[which(rgdemask[]==0)]))
  
  # get sample
  nonGDE_trainsamp<-rasterToPoints(rgdemask, fun=function(x){x==0}, spatial=TRUE)[sampsize2,]
  
  # 
  #define class as non-GDE = 0
  nonGDE_trainsamp$class<-rep(0, length(sampsize2))
  
  # convert to sf object
  nonGDE_trainsamp<-st_as_sf(nonGDE_trainsamp)
  
  # plot(st_geometry(NV_nonGDE_trainsamp))
  return (list(nonGDE_trainsamp,GDE_trainsamp))
}


#################### import states/countries to define boundaries within which to sample non-GDE points

australia <- st_as_sf(map("Australia", plot = FALSE, fill = TRUE)) #***LOOK FOR COUNTRY BOUNDARIES
dtw <-raster('DTW_global_sm0.tif')

# use consistent projection
USAprj<-'+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=37.5 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +datum=NAD83 +units=m no_defs'
latlongprj<-"+init=epsg:4326 +proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +towgs84=0,0,0"
