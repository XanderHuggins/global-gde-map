library(here)
library(tibble)
library(tidyverse)

# Calculate base GDE stats

# load GDE data
gde_dat = list.files("D:/Geodatabase/GDEs/Processed_GDE_layers/data_out/gdeXprotXcont_dat/", 
                     pattern = ".rds$", full.names = T) |> 
  map_dfr(readRDS) 

# group by z ID (gdeXprotXcont)
gde_dat = gde_dat |> 
  group_by(z) |> 
  summarise(area = sum(area))

### --- from the tile processing script: 
# XYW, where X is GDE class, Y is protected status, W is continental membership

############### READ ME
## GDE class:
## 2 : not likely GDE 
## 1 : likely GDE
## 0 : not analyzed 

## Protected status:
## 9 : high level of protection + policy
## 8 : low level of protection + policy
## 7 : unknown protection class + policy 
## 6 : policy but no protection class
## 3 : high level of protection
## 2 : low level of protection
## 1 : unknown protection class
## 0 : no protection

### Continents:
## 6 : South America
## 5 : Europe
## 4 : North America
## 3 : Australia/Oceania
## 2 : Asia
## 1 : Africa
## 0 : NoData

############### end readme

gde_dat$gde = trunc(gde_dat$z/100)
gde_dat$prot = trunc((gde_dat$z - (gde_dat$gde*100))/10)
gde_dat$cont = gde_dat$z - (gde_dat$gde*100) - (gde_dat$prot*10)

# calculate total GDE area
GDE_area = gde_dat |> filter(gde == 1) |> pull(area) |> sum() 
message(GDE_area/1e6)
#> 8.33854768106021
#> 8.34 million km2 of GDEs

# calculate total area analyzed
ANL_area = gde_dat |> filter(gde >= 1) |> pull(area) |> sum() 
message(ANL_area/1e6) 
#> 23.1735103643138
#> 23.2 million km2 of area analyzed

message((ANL_area - GDE_area)/1e6)
#> 14.8349 million km2 of area analyzed that is not likely a GDE

# proportion of GDE area to analzed area
GDE_area/ANL_area 
#> 0.359831
#> 35.98%

# GDEs under any form of protection
anyPROT_area = gde_dat |> filter(prot > 0 & gde == 1) |> pull(area) |> sum()
message(anyPROT_area/1e6) 
#> 1.75630046171183 million km2

# proportion of GDEs under any form of protection
anyPROT_area/GDE_area 
#> 0.2106243
#> 21%

# GDEs in protected areas with "high" protection
highPROT_area = gde_dat |> filter(prot >= 7) |> filter(gde == 1) |> 
  pull(area) |> sum()
message(highPROT_area/1e6) 
#> 0.208524222117192 million km2

# proportion of GDEs in PAs with "high" levels of protection
highPROT_area/GDE_area # 6%
#> 0.02500726

# Create plot of Continent distribution of GDE area

# look-up table for names
lut_names = data.frame(
  id = seq(1,6),
  nm = c("AF", "AS", "OC", "NA", "EU", "SA")
)

# summary stats
continent_summary = gde_dat |> 
  dplyr::group_by(cont, gde) |> 
  reframe(
    area = sum(area, na.rm = T)/1e6
  ) |> 
  filter(gde > 0)
continent_summary

plot_dat = continent_summary |> filter(gde == 1) |> 
  dplyr::select(c('cont', 'area')) |> 
  set_colnames(c('cont', 'gde_area'))
plot_dat$anl_area_no_gde = continent_summary |> filter(gde == 2) |> pull(area)

gde_sum = continent_summary |> filter(gde == 1) |> pull(area) |> sum() 
nogde_sum = continent_summary |> filter(gde == 2) |> pull(area) |> sum()
tot_area = gde_sum + nogde_sum

plot_dat = merge(x = plot_dat, y = lut_names, by.x = "cont", by.y = "id")
plot_dat$pcttot = round(100 * plot_dat$gde_area / gde_sum, 2)
plot_dat$contdens = round(plot_dat$gde_area / (plot_dat$gde_area + plot_dat$anl_area_no_gde), 2)

## Summary stats:
plot_dat
#   cont  gde_area anl_area_no_gde nm pcttot contdens
# 1    1 1.9754143       6.0629523 AF  23.69     0.25
# 2    2 4.1838312       4.7419317 AS  50.17     0.47
# 3    3 0.7152141       3.0445830 OC   8.58     0.19
# 4    4 0.5525260       0.4130659 NA   6.63     0.57
# 5    5 0.2123544       0.1654132 EU   2.55     0.56
# 6    6 0.6918114       0.4024721 SA   8.30     0.63

######### -
## Plot bar plot for Figure 1
######### -

plot_dat$rank = rank(-plot_dat$gde_area)

plot_df = plot_dat |> dplyr::select(!c(nm, pcttot, contdens)) |> melt(id.vars = c("rank", "cont"))
plot_df$variable %<>% factor(levels = c('anl_area_no_gde', 'gde_area'))

ggplot(data = plot_df, aes(x = rank, y = value, fill = variable)) +
  geom_bar(position = "stack", stat = "identity", col = "black") +
  scale_fill_manual(values = c('#F8BF66', '#1B960A')) +
  cus_theme + theme(plot.margin = unit(c(2,5,2,2), "mm"))
# x-axis order: AS, AF, OC, SA, NA, EU

ggsave(filename = here("plots/gde_area_continents.png"),
       plot = last_plot(), 
       device = "png",
       dpi = 400, 
       width = 100,
       height = 60,
       units = "mm")
