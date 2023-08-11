
######################################### -
## Calculate bivariate relationship between GDE density and GWS trends from GRACE 
######################################### -

# load dependencies
library(here); library(reldist)
invisible(sapply(paste0(here("R/setup"), "/", list.files(here("R/setup"))), source))

# Import the raw GDE data at 5 and 30 arcminute
# gde_05arcmin = terra::rast("D:/Geodatabase/GDEs/00_aggregated_tiles/mosiac_sets/GDE_drylands_05arcmin.tif")
gde_30arcmin = terra::rast("D:/Geodatabase/GDEs/00_aggregated_tiles/mosiac_sets/GDE_drylands_30arcmin.tif")
gde_dens = gde_30arcmin[[3]]
gde_area = gde_30arcmin[[1]]

# Import GWS trends
gws = terra::rast("D:/Geodatabase/GRACE/Hrishi/gws_trend_mean.tif") |> 
  terra::crop(gde_dens) |> 
  mask(gde_dens)

# reclassify GDE density into five bins
rcl.m = c(0  , 0.01, 1,
          0.01, 0.025, 2,
          0.025, 0.05, 3,
          0.05, 0.1, 4,
          0.1, 0.2, 5,
          0.2, 0.4, 6,
          0.4, Inf, 7) |> 
  matrix(ncol = 3, byrow = TRUE)

gde_class = terra::classify(x = gde_dens, rcl = rcl.m, include.lowest = TRUE)

## reclassify GWS into five bins, based on absolute magnitude percentils
gw_ptls = c(gws, gde_area, WGS84_areaRaster(0.5) |> rast() |> terra::crop(gws)) |> 
  as.data.frame() |> set_colnames(c('gws', 'gde_area', 'area')) |> 
  mutate(gws = abs(gws)) |> 
  summarise(
    wtd.quantile(x = gws, q = c(0.5, 0.80, 0.95), weight = gde_area, na.rm = T)
  ) |> as.vector() |> unlist()

rcl.m = c(-Inf, -gw_ptls[3], 1,
          -gw_ptls[3], -gw_ptls[2], 2,
          -gw_ptls[2], -gw_ptls[1], 3,
          -gw_ptls[1], gw_ptls[1], 4,
          gw_ptls[1], gw_ptls[2], 5,
          gw_ptls[2], gw_ptls[3], 6,
          gw_ptls[3], Inf, 7) |> 
  matrix(ncol = 3, byrow= TRUE)

gws_class = terra::classify(x = gws, rcl = rcl.m, include.lowest = TRUE)

# Create unique bivariate class
gde_gws = (gde_class * 10) + (gws_class)

# writeRaster(x = gde_gws, filename = here("data/gde_gws_bivar_v2.tif"), overwrite = TRUE)

##################### --
#### Calculate the percent of GDEs that exist in areas with drying groundwater storage trends ---
##################### --
gde_df = c(gde_area, gws) |> 
  as.data.frame() |> 
  set_colnames(c('gde', 'gws')) |> 
  drop_na()

######## Key summary statistics
(gde_df |> filter(gws < -0.00)  |> pull(gde) |> sum(na.rm = T) /
  gde_df |> pull(gde) |> sum(na.rm = T) ) |> round(3)
#> 52.9 %

gde_df |> pull(gde) |> sum(na.rm = T)
#> 7201217

gde_df |> filter(gws < 0.00)  |> pull(gde) |> sum(na.rm = T) / 1e6
#> 3806721

gde_df |> filter(gws > 0.00)  |> pull(gde) |> sum(na.rm = T)
#> 3394496

(gde_df |> filter(gws > 0.00)  |> pull(gde) |> sum(na.rm = T) /
  gde_df |> pull(gde) |> sum(na.rm = T) ) |> round(3)
#> 47.1%

# Identify distribution across continents
conts = terra::vect("D:/Geodatabase/Admin-ocean-boundaries/continents/Continents.shp") |> 
  terra::rasterize(y = gde_30arcmin[[1]], field = "OBJECTID", touches = T) |> 
  terra::resample(y = gde_30arcmin[[1]], method = "near") |> 
  terra::classify(rcl = matrix(c(5, 3,   # Combine Australia and Oceania
                                 8, 5,   # Move Europe to value 5
                                 7, NA), # Remove Antactica
                               ncol = 2, byrow = TRUE))

gde_df = c(gde_area, gws, conts) |> 
  as.data.frame() |> 
  set_colnames(c('gde', 'gws', 'conts')) |> 
  drop_na()

lut_names = data.frame(
  id = seq(1,6),
  nm = c("AF", "AS", "OC", "NA", "EU", "SA")
)

for (i in 1:6) {
  gde_area_dry = gde_df |> filter(conts == i) |> filter(gws < 0) |> pull(gde) |> sum(na.rm = T)
  gde_area_tot = gde_df |> filter(conts == i) |> pull(gde) |> sum(na.rm = T)
  
  message("continent ", lut_names$nm[i], " had a drying GDE percentage of: ", round(100*gde_area_dry/gde_area_tot, 2))
  
}

## Key summary statistics
# continent AF had a drying GDE percentage of: 17.02
# continent AS had a drying GDE percentage of: 75.29
# continent OC had a drying GDE percentage of: 29.44
# continent NA had a drying GDE percentage of: 65.16
# continent EU had a drying GDE percentage of: 90.18
# continent SA had a drying GDE percentage of: 36.55

#############-
## Plot the distribution of GDE density vs GWS trend per FEOW
#############-

# import feow file
feow = terra::vect("D:/Geodatabase/Ecological/Ecoregions/data/commondata/data0/feow_ecoregions.shp") |> as.data.frame()

feowr = terra::vect("D:/Geodatabase/Ecological/Ecoregions/data/commondata/data0/feow_ecoregions.shp") |> 
  rasterize(y = gde_gws, field = "ECO_ID", touches = T)
  
feow_stat = c(feowr, gde_dens, gws, gde_area, WGS84_areaRaster(0.5) |> rast() |> terra::crop(gde_gws)) |> 
  as.data.frame() |> 
  set_colnames(c('feowid', 'gde_dens', 'gws', 'gde_area', 'area')) |> 
  group_by(feowid) |> 
  summarise(
    gded = weighted.mean(x = gde_dens, w = area, na.rm = T),
    gdea = sum(gde_area, na.rm = T),
    gws  = weighted.mean(x = gws, w = gde_area, na.rm = T)
  ) |> 
  drop_na()
feow_stat

# Import names of highlighted basins
feow_flag = terra::vect(here("data/feow-focus.sqlite")) |> 
  as.data.frame() |> 
  pull(eco_id)

'%!in%' <- function(x,y)!('%in%'(x,y))

# pull values for these basins
feow_stat |> filter(feowid %in% c(feow_flag, 450)) |> mutate(gws = gws *1000)



# find a feow that is drying and high GDE density
feow_stat |> filter(gded > 0.2 & gws < -8)
feow_stat |> filter(feowid == 703)

ggplot(data = feow_stat, aes(x = gws, y = gded, label = feowid)) +
  geom_point(alpha = 0.1) +
  geom_text(size = 2)



x_breaks = c(-gw_ptls, 0, gw_ptls) |> as.vector() 

feow_stat$gded[feow_stat$gded > 0.4] = 0.4
feow_stat$gws[feow_stat$gws < -0.025] = -0.025

ggplot() +
  geom_point(data = feow_stat |> filter(feowid %!in% feow_flag), aes(x = gws, y = gded, size = gdea), fill = "#181717", alpha = 0.5) +
  geom_point(data = feow_stat |> filter(feowid %in% feow_flag), aes(x = gws, y = gded, size = gdea), pch = 21, fill = "#FED400") +
  scale_size(range = c(2,12)) +
  cus_theme +
  theme(axis.line = element_line(linewidth = 1), 
        panel.grid.major = element_line(1, linetype = "dotted", colour = 'grey'),
        axis.text = element_blank(),
        axis.title =  element_blank(),
        plot.margin = margin(1,1,1.5,1.2, "cm")) +
  geom_vline(xintercept = 0, linewidth = 1.5) +
  scale_y_continuous(breaks = seq(0, 1, by = 0.1)) +
  scale_x_continuous(breaks = x_breaks) +
  coord_cartesian(expand = 0, xlim = c(-0.025, 0.025), clip = "off") 
   

ggsave(filename = here("plots/gde_gws_scatter.png"),
       plot = last_plot(), 
       device = "png",
       width = 13,
       height = 11,
       dpi = 400,
       units = "cm")


# Now make heatmap based on GDE distribution across bivariate map
gde_gws_sumstat = c(gde_gws, WGS84_areaRaster(0.5) |> rast() |> crop(gde_gws)) |> 
  as.data.frame() |> set_colnames(c('id', 'area')) |> 
  group_by(id) |> 
  summarise(
    area = sum(area, na.rm = T)
  ) |> 
  drop_na() |> 
  mutate(
    area = round(100*area/sum(area), 1),
    yval = trunc(id/10),
    xval = id - (yval*10)
  )

gde_gws_sumstat |> 
  ggplot(aes(x = xval, y = yval, fill = area)) + 
  geom_tile() +
  scale_fill_gradientn(colours = met.brewer("Hokusai2", n = 20), limits = c(0.1,10), oob = scales::squish) +
  theme_void() +
  theme(legend.position = "None") 

ggsave(plot = last_plot(),
       file= here("plots/gde_gws_grid_heatmap.png"), bg = "transparent",
       dpi= 400, width = 5, height = 5, units = "cm")