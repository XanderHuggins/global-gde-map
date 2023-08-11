library(here)
invisible(sapply(paste0(here("R/setup"), "/", list.files(here("R/setup"))), source)) 

# GRACE GWS trends per freshwater ecoregion

# Import ecoregions
feow = sf::read_sf("D:/Geodatabase/Ecological/Ecoregions/Freshwater-databasin/data/commondata/data0/feow_ecoregions.shp")

# Now import GRACE GWS trends from VIC and NOAH
gws_vic = terra::rast("D:/Geodatabase/GRACE/Hrishi/GRACE_gws_trend/gldas_2.1_vic_local_trends.nc")[[5]]
terra::ext(gws_vic) = c(-180, 180, -90, 90)

gws_noah = terra::rast("D:/Geodatabase/GRACE/Hrishi/GRACE_gws_trend/gldas_2.1_noah_local_trends.nc")[[5]]
terra::ext(gws_noah) = c(-180, 180, -90, 90)

gws_mean = mean(c(gws_vic, gws_noah))

# convert units of gws from Gt/yr to mm/yr
gws_mean = gws_mean * 1e12 # Gt to kg 
gws_mean = gws_mean / 1e3  # kg to m3 using using assumed density of 1000kg/m3
surf_area = terra::rast(WGS84_areaRaster(0.5))*1e6 # from km2 to m2
gws_mean = gws_mean/surf_area #m3 to m by dividing by surface area

terra::writeRaster(gws_mean,
                   filename = "D:/projects/dryland-GDEs/additional_data/grace_gws.tif",
                   filetype = "GTiff",
                   overwrite = T)

# Now convert FEOW to raster
gdal_rasterize(src_datasource = "D:/Geodatabase/Ecological/Ecoregions/Freshwater/feow_hydrosheds.shp", 
               dst_filename = "D:/Geodatabase/Ecological/Ecoregions/Freshwater/feow_0d5_id.tif", 
               at  = TRUE,
               a = "FEOW_ID",
               te = c(-180, -90, 180, 90),
               tr = c(0.5, 0.5))

feow_r = terra::rast("D:/Geodatabase/Ecological/Ecoregions/Freshwater/feow_0d5_id.tif")
feow_r[feow_r == 0] = NA

all_data = c(feow_r, gws_mean, surf_area) |> 
  as.data.frame() |> 
  set_colnames(c('feow_id', 'gws', 'area'))

# calculate area-weighted trend per feow
feow_gws = all_data |> 
  group_by(feow_id) |> 
  summarize(
    gws_mean = weighted.mean(x = gws, w = area, na.rm = T)
  )

# merge id with shapefile
feow = merge(x = feow, y = feow_gws, by.x = "ECO_ID", by.y = "feow_id", all.x = T)
st_crs(feow) = 4326

sf::write_sf(obj = feow,
             dsn = "D:/projects/dryland-GDEs/additional_data/feow_gws_trends.sqlite",
             layer = "gws_trends.sqlite",
             driver = "SQLite",
             overwrite = T)
