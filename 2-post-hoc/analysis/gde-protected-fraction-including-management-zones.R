library(here)
invisible(sapply(paste0(here("R/setup"), "/", list.files(here("R/setup"))), source)) 

# import all tile names
all_tiles = list.files("D:/projects/dryland-GDEs/summary_exports/GDE_area/", full.names = F)
all_tiles = all_tiles |> gsub(pattern = "_gde_area.rds", replacement = "")

length(all_tiles) # 436

# Tile names from all of the zones where there is sustainable management of GDEs
# California
ca_tiles_excl = sf::read_sf("D:/Geodatabase/GDEs/Custom_tile_groups/Protected_status/California-exclusive.sqlite") |> 
  as.data.frame() |> pull(name)
ca_tiles_part = sf::read_sf("D:/Geodatabase/GDEs/Custom_tile_groups/Protected_status/California-partial.sqlite") |> 
  as.data.frame() |> pull(name)

# South Africa
sa_tiles_excl = sf::read_sf("D:/Geodatabase/GDEs/Custom_tile_groups/Protected_status/SouthAfrica-exclusive.sqlite") |> 
  as.data.frame() |> pull(name)
sa_tiles_part = sf::read_sf("D:/Geodatabase/GDEs/Custom_tile_groups/Protected_status/SouthAfrica-partial.sqlite") |> 
  as.data.frame() |> pull(name)

# Australia
au_tiles_excl = sf::read_sf("D:/Geodatabase/GDEs/Custom_tile_groups/Protected_status/Australia-exclusive.sqlite") |> 
  as.data.frame() |> pull(name)
au_tiles_part = sf::read_sf("D:/Geodatabase/GDEs/Custom_tile_groups/Protected_status/Australia-partial.sqlite") |> 
  as.data.frame() |> pull(name)

# European Union
eu_tiles_excl = sf::read_sf("D:/Geodatabase/GDEs/Custom_tile_groups/Protected_status/EU-exclusive.sqlite") |> 
  as.data.frame() |> pull(name)
eu_tiles_part = sf::read_sf("D:/Geodatabase/GDEs/Custom_tile_groups/Protected_status/EU-partial.sqlite") |> 
  as.data.frame() |> pull(name)


# Create list of these names to remove from overall list
rm_list = c(ca_tiles_excl, ca_tiles_part, sa_tiles_excl, sa_tiles_part, au_tiles_excl, au_tiles_part, eu_tiles_excl, eu_tiles_part)
length(rm_list) # 84

# Create list of tiles that are independent of the sustaiable management jurisdictions
ind_tiles = all_tiles[(all_tiles %in% rm_list) == FALSE]
length(ind_tiles) # 352

# Calculate sum of GDE area under protection in these independent tiles
# 1000 = high protection and excluded
# 1001 = high protection and GDE
# 1002 = high protection and not GDE
# 2000 = low protection and excluded  
# 2001 = low protection and GDE
# 2002 = low protection and not GDE
prot_wd = "D:/projects/dryland-GDEs/summary_exports/PROT_GDE_area/"
df_ind = readr::read_rds(paste0(prot_wd, ind_tiles[1], "_prot_gde_area.rds"))
for (i in 2:length(ind_tiles)) {
  if (file.exists(paste0(prot_wd, ind_tiles[i], "_prot_gde_area.rds"))) {
    df_ind = rbind(df_ind, readr::read_rds(paste0(prot_wd, ind_tiles[i], "_prot_gde_area.rds")))
    }
}
df_ind = df_ind |> group_by(z) |> summarize(area = sum(area, na.rm = T))
df_ind$prot = round(df_ind$z / 1e3, 2)
df_ind$gde = df_ind$z - (df_ind$prot*1e3)
independent_protected_GDE = df_ind |> filter(gde == 1) |> pull(area) |> sum()/1e6


# Now calculate sum of all GDE area within sustainable management areas, for tiles entirely within the jurisdiction
# 0 = not analyzed
# 1 = GDE
# 2 = not GDE
gde_wd = "D:/projects/dryland-GDEs/summary_exports/GDE_area/"
exl_tiles = c(ca_tiles_excl, sa_tiles_excl, au_tiles_excl, eu_tiles_excl)
df_exl = readr::read_rds(paste0(gde_wd, exl_tiles[1], "_gde_area.rds"))
for (i in 2:length(exl_tiles)) {
  if (file.exists(paste0(gde_wd, exl_tiles[i], "_gde_area.rds"))) {
    df_exl = rbind(df_exl, readr::read_rds(paste0(gde_wd, exl_tiles[i], "_gde_area.rds")))
  }
}
df_exl = df_exl |> group_by(z) |> summarize(area = sum(area, na.rm = T))
exclusive_protected_GDE = df_exl |> filter(z == 1) |> pull(area) |> sum()/1e6


# Now calculate the fraction of GDE in tiles that span sustainable management areas
tile_wd = "D:/Geodatabase/GDEs/GlobalGDE_v5/"

# Start in California
ca_vect = terra::vect("D:/Geodatabase/GDEs/Custom_tile_groups/Protected_status/California-administrative-boundary.sqlite")
ca_vect$f = 1

for (i in 3:length(ca_tiles_part)) {
  print(i)
  # import GDE tile 
  gde_tile_t = terra::rast(paste0(tile_wd, ca_tiles_part[i], ".tif"))
  gde_tile_r = raster(paste0(tile_wd, ca_tiles_part[i], ".tif"))
  
  # snap to extent
  raster::extent(gde_tile_r) = round(raster::extent(gde_tile_r), 0)
  terra::ext(gde_tile_t) = round(terra::ext(gde_tile_t), 0)
  message('gde tile imported')
  
  # Import area raster
  area_tile_in = raster(paste0("D:/projects/dryland-GDEs/area_tiles/", ca_tiles_part[i], "_area.tif")) 
  message('area tile imported')
  
  # Convert california vector to raster for tile
  vect_tile_crop = terra::crop(x = ca_vect, y = terra::ext(gde_tile_t)) |> st_as_sf() |> st_cast(to = "MULTIPOLYGON")
  vect_tile_crop_r = fasterizeDT(x = vect_tile_crop, raster = gde_tile_r, field = 'f', fun = "max")
  message('vector cropped and rasterized')
  
  # Multiply sustainable management jurisdiction mask by GDE tile
  gde_masked = gde_tile_r * vect_tile_crop_r
  message('gde masked by vector')
  
  # Calculate area sum for this masked tile
  masked_gde_area = rasterDT::zonalDT(x = area_tile_in, z = gde_masked, fun = sum, na.rm = T)
  message('zonal statistics done')
  
  write_rds(x = masked_gde_area |> as.data.frame() |> set_colnames(c('z', 'area')),
            file = paste0("D:/projects/dryland-GDEs/summary_exports/Masked_Prot_GDE_area/", ca_tiles_part[i], ".rds"))
  
}


# South Africa
sa_vect = terra::vect("D:/Geodatabase/GDEs/Custom_tile_groups/Protected_status/SouthAfrica-administrative-boundary.sqlite")
sa_vect$f = 1

for (i in 3:length(sa_tiles_part)) {
  print(i)
  # import GDE tile 
  gde_tile_t = terra::rast(paste0(tile_wd, sa_tiles_part[i], ".tif"))
  gde_tile_r = raster(paste0(tile_wd, sa_tiles_part[i], ".tif"))
  
  # snap to extent
  raster::extent(gde_tile_r) = round(raster::extent(gde_tile_r), 0)
  terra::ext(gde_tile_t) = round(terra::ext(gde_tile_t), 0)
  message('gde tile imported')
  
  # Import area raster
  area_tile_in = raster(paste0("D:/projects/dryland-GDEs/area_tiles/", sa_tiles_part[i], "_area.tif")) 
  message('area tile imported')
  
  # Convert california vector to raster for tile
  vect_tile_crop = terra::crop(x = sa_vect, y = terra::ext(gde_tile_t)) |> st_as_sf() |> st_cast(to = "MULTIPOLYGON")
  vect_tile_crop_r = fasterizeDT(x = vect_tile_crop, raster = gde_tile_r, field = 'f', fun = "max")
  message('vector cropped and rasterized')
  
  # Multiply sustainable management jurisdiction mask by GDE tile
  gde_masked = gde_tile_r * vect_tile_crop_r
  message('gde masked by vector')
  
  # Calculate area sum for this masked tile
  masked_gde_area = rasterDT::zonalDT(x = area_tile_in, z = gde_masked, fun = sum, na.rm = T)
  message('zonal statistics done')
  
  write_rds(x = masked_gde_area |> as.data.frame() |> set_colnames(c('z', 'area')),
            file = paste0("D:/projects/dryland-GDEs/summary_exports/Masked_Prot_GDE_area/", sa_tiles_part[i], ".rds"))
  
}

# European Union
eu_vect = terra::vect("D:/Geodatabase/GDEs/Custom_tile_groups/Protected_status/EU-administrative-boundary.sqlite")
eu_vect$f = 1

for (i in 1:length(eu_tiles_part)) {
  print(i)
  # import GDE tile 
  gde_tile_t = terra::rast(paste0(tile_wd, eu_tiles_part[i], ".tif"))
  gde_tile_r = raster(paste0(tile_wd, eu_tiles_part[i], ".tif"))
  
  # snap to extent
  raster::extent(gde_tile_r) = round(raster::extent(gde_tile_r), 0)
  terra::ext(gde_tile_t) = round(terra::ext(gde_tile_t), 0)
  message('gde tile imported')
  
  # Import area raster
  area_tile_in = raster(paste0("D:/projects/dryland-GDEs/area_tiles/", eu_tiles_part[i], "_area.tif")) 
  message('area tile imported')
  
  # Convert california vector to raster for tile
  vect_tile_crop = terra::crop(x = eu_vect, y = terra::ext(gde_tile_t)) |> st_as_sf() |> st_cast(to = "MULTIPOLYGON")
  vect_tile_crop_r = fasterizeDT(x = vect_tile_crop, raster = gde_tile_r, field = 'f', fun = "max")
  message('vector cropped and rasterized')
  
  # Multiply sustainable management jurisdiction mask by GDE tile
  gde_masked = gde_tile_r * vect_tile_crop_r
  message('gde masked by vector')
  
  # Calculate area sum for this masked tile
  masked_gde_area = rasterDT::zonalDT(x = area_tile_in, z = gde_masked, fun = sum, na.rm = T)
  message('zonal statistics done')
  
  write_rds(x = masked_gde_area |> as.data.frame() |> set_colnames(c('z', 'area')),
            file = paste0("D:/projects/dryland-GDEs/summary_exports/Masked_Prot_GDE_area/", eu_tiles_part[i], ".rds"))
  
}

# Australia
au_vect = terra::vect("D:/Geodatabase/GDEs/Custom_tile_groups/Protected_status/Australia-administrative-boundary.sqlite")
au_vect$f = 1

for (i in 1:length(au_tiles_part)) {
  print(i)
  # import GDE tile 
  gde_tile_t = terra::rast(paste0(tile_wd, au_tiles_part[i], ".tif"))
  gde_tile_r = raster(paste0(tile_wd, au_tiles_part[i], ".tif"))
  
  # snap to extent
  raster::extent(gde_tile_r) = round(raster::extent(gde_tile_r), 0)
  terra::ext(gde_tile_t) = round(terra::ext(gde_tile_t), 0)
  message('gde tile imported')
  
  # Import area raster
  area_tile_in = raster(paste0("D:/projects/dryland-GDEs/area_tiles/", au_tiles_part[i], "_area.tif")) 
  message('area tile imported')
  
  # Convert california vector to raster for tile
  vect_tile_crop = terra::crop(x = au_vect, y = terra::ext(gde_tile_t)) |> st_as_sf() |> st_cast(to = "MULTIPOLYGON")
  vect_tile_crop_r = fasterizeDT(x = vect_tile_crop, raster = gde_tile_r, field = 'f', fun = "max")
  message('vector cropped and rasterized')
  
  # Multiply sustainable management jurisdiction mask by GDE tile
  gde_masked = gde_tile_r * vect_tile_crop_r
  message('gde masked by vector')
  
  # Calculate area sum for this masked tile
  masked_gde_area = rasterDT::zonalDT(x = area_tile_in, z = gde_masked, fun = sum, na.rm = T)
  message('zonal statistics done')
  
  write_rds(x = masked_gde_area |> as.data.frame() |> set_colnames(c('z', 'area')),
            file = paste0("D:/projects/dryland-GDEs/summary_exports/Masked_Prot_GDE_area/", au_tiles_part[i], ".rds"))
  
}


# Now calculate sum of all GDE area within sustainable management areas, for tiles partially within the jurisdiction
# 0 = not analyzed
# 1 = GDE
# 2 = not GDE
gde_wd = "D:/projects/dryland-GDEs/summary_exports/Masked_Prot_GDE_area/"
part_tiles = c(ca_tiles_part, sa_tiles_part, au_tiles_part, eu_tiles_part)
df_part = readr::read_rds(paste0(gde_wd, part_tiles[1], ".rds"))
for (i in 2:length(part_tiles)) {
  if (file.exists(paste0(gde_wd, part_tiles[i], ".rds"))) {
    df_part = rbind(df_part, readr::read_rds(paste0(gde_wd, part_tiles[i], ".rds")))
  }
}
df_part = df_part |> group_by(z) |> summarize(area = sum(area, na.rm = T))
partial_protected_GDE = df_part |> filter(z == 1) |> pull(area) |> sum()/1e6


# sum of protected GDEs areas
prot_GDE = partial_protected_GDE + exclusive_protected_GDE + independent_protected_GDE # 1.24 million km2

prot_GDE / 5.264586 # 23.7%