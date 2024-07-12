library(here)
library(terra)

aus = terra::vect("D:/Geodatabase/GDEs/Custom_tile_groups/Protected_status/Australia-administrative-boundary.sqlite")
crs(aus) = "+proj=longlat"
aus$id = 1
aus = aus[,3]

saf = terra::vect("D:/Geodatabase/GDEs/Custom_tile_groups/Protected_status/SouthAfrica-administrative-boundary2.sqlite")
crs(saf) = "+proj=longlat"
saf$id = 2
saf = saf[,3]

cal = terra::vect("D:/Geodatabase/GDEs/Custom_tile_groups/Protected_status/California-administrative-boundary.sqlite")
crs(cal) = "+proj=longlat"
cal$id = 3
cal = cal[,11]

eur = terra::vect("D:/Geodatabase/GDEs/Custom_tile_groups/Protected_status/EU-administrative-boundary.sqlite")
crs(eur) = "+proj=longlat"
eur$id = 4
eur = eur[,4]
eur = terra::aggregate(x = eur, dissolve = TRUE)

gab = terra::vect("D:/Geodatabase/Basins/GAB_Hydrogeological_Boundary_GABWRA_v01/Revised_GAB_Boundary.shp")
gab = terra::project(x = gab, y="+proj=longlat")
gab$id = 5
gab = gab[,2]

prot_admins = rbind(aus, saf, cal, eur, gab)
plot(prot_admins)

writeVector(x = prot_admins, 
            filename = here("data/plotting_accessories/all_juris_with_GDE_protection_policies.sqlite"),
            filetype = "SQLite")