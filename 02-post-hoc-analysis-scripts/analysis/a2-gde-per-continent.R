
######################################### -
## Calculate GDE area per continent, at 5 arcminute 
######################################### -

# load dependencies
library(here)
invisible(sapply(paste0(here("R/setup"), "/", list.files(here("R/setup"))), source))

# Import the raw GDE data at 5 and 30 arcminute
gde_05arcmin = terra::rast("D:/Geodatabase/GDEs/00_aggregated_tiles/mosiac_sets/GDE_drylands_05arcmin.tif")
gde_30arcmin = terra::rast("D:/Geodatabase/GDEs/00_aggregated_tiles/mosiac_sets/GDE_drylands_30arcmin.tif")

conts = terra::vect("D:/Geodatabase/Admin-ocean-boundaries/continents/Continents.shp") |> 
  terra::rasterize(y = gde_30arcmin[[1]], field = "OBJECTID", touches = T) |> 
  terra::resample(y = gde_05arcmin[[1]], method = "near") |> 
  terra::classify(rcl = matrix(c(5, 3,   # Combine Australia and Oceania
                                 8, 5,   # Move Europe to value 5
                                 7, NA), # Remove Antactica
                               ncol = 2, byrow = TRUE))

# look-up table for names
lut_names = data.frame(
  id = seq(1,6),
  nm = c("AF", "AS", "OC", "NA", "EU", "SA")
)

# summary stats
gde_stat = c(gde_05arcmin[[1]], gde_05arcmin[[4]], conts) |> 
  as.data.frame() |> 
  group_by(OBJECTID) |> 
  summarise(
    gde_area = sum(GDE_sqkm, na.rm = T)/1e6,
    anl_area = sum(AA_sqkm, na.rm = T)/1e6
  ) |> 
  mutate(
    nongde = anl_area - gde_area
  ) |> 
  dplyr::select(OBJECTID, gde_area, nongde)

########## -
## BASE SUMMARY STATISTICS
########## -
gde_sum = gde_stat |> pull(gde_area) |> sum() 
nogde_sum = gde_stat |> pull(nongde) |> sum() 
tot_area = gde_sum + nogde_sum

gde_sum   ## 8.338548 million km2
nogde_sum ## 14.83496 million km2
tot_area  ## 23.17351 million km2

gde_stat = merge(x = gde_stat, y = lut_names, by.x = "OBJECTID", by.y = "id")
gde_stat$pcttot = round(100 * gde_stat$gde_area / sum(gde_stat$gde_area), 2)
gde_stat$contdens = round(gde_stat$gde_area / (gde_stat$gde_area + gde_stat$nongde), 2)

## Sumamry stats:
#> gde_stat
# OBJECTID  gde_area    nongde   nm pcttot contdens
# 1        1 1.9765056 6.0636411 AF  23.70     0.25
# 2        2 4.1845410 4.7428196 AS  50.18     0.47
# 3        3 0.7161729 3.0450823 OC   8.59     0.19
# 4        4 0.5542045 0.4138883 NA   6.65     0.57
# 5        5 0.2142333 0.1664900 EU   2.57     0.56
# 6        6 0.6928176 0.4029865 SA   8.31     0.63

######### -
## Plot bar plot for Figure 1
######### -

gde_stat$rank = rank(-gde_stat$gde_area)

plot_df = gde_stat |> dplyr::select(!c(nm, OBJECTID)) |> melt(id.vars = "rank") 
plot_df$variable %<>% factor(levels = c('nongde', 'gde_area'))

ggplot(data = plot_df, aes(x = rank, y = value, fill = variable)) +
  geom_bar(position = "stack", stat = "identity", col = "black") +
  scale_fill_manual(values = c('#F8BF66', '#1B960A')) +
  cus_theme + theme(plot.margin = unit(c(2,5,2,2), "mm"))
# x-axis order: AS, AF, OC, SA, NA, EU

ggsave(filename = "D:/projects/dryland-GDEs/plots/gde_area_continents_v2.png",
       plot = last_plot(), 
       device = "png",
       width = 100,
       height = 60,
       units = "mm")