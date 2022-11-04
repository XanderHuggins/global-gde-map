# Name: packages-in.R
# Description: Import all packages used in workflow

# general
library(tidyverse)
library(magrittr)

# spatial
library(terra) 
library(raster) 
library(rasterDT)
library(sf)
library(ncdf4)
library(fasterize)
library(rgdal)
library(gdalUtilities)

# plotting
library(scico) 
library(MetBrewer)
library(viridisLite)
library(RColorBrewer)
library(scales)

# Spatial plotting
library(rnaturalearth)
library(tmaptools)
library(tmap)

# stats
library(DescTools)