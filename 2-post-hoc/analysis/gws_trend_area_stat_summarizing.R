library(here)
invisible(sapply(paste0(here("R/setup"), "/", list.files(here("R/setup"))), source)) 

# import all GDE areas

all_files = list.files("D:/projects/dryland-GDEs/summary_exports/GWS_GDE_area/", full.names = T)

df_all = readr::read_rds(all_files[1])

for (i in 2:length(all_files)) {
  df_all = rbind(df_all, readr::read_rds(all_files[i]))
}

df_all = df_all |> group_by(z) |> summarize(area = sum(area, na.rm = T))

df_all$gws_bin = round(df_all$z / 1e3, 2)
df_all$gde = df_all$z - (df_all$gws_bin*1e3)

# for reference:
gws_rcl = data.frame(low  = seq(-0.1, 0.1-0.005, by = 0.005),
                     high = seq(-0.1+0.005, 0.1, by = 0.005),
                     new  = seq(1, 40, length.out = 40)) |> 
  as.matrix()

# Calculate area of GDE in groundwater depletion regions
df_all |> filter(gws_bin <= 20 & gde == 1) |> pull(area) |> sum()/1e6
df_all |> filter(gws_bin > 20 & gde == 1) |> pull(area) |> sum()/1e6
df_all |> filter(gde == 1) |> pull(area) |> sum()/1e6


# calculate groundwater trends for GDEs per continent
tiles_AS = terra::vect("D:/projects/dryland-GDEs/continent_id_tiles/north_america_tiles.sqlite")
tiles_AS = terra::vect("D:/projects/dryland-GDEs/continent_id_tiles/asia_tiles.sqlite")
tiles_AF = terra::vect("D:/projects/dryland-GDEs/continent_id_tiles/africa_tiles.sqlite")
tiles_SA = terra::vect("D:/projects/dryland-GDEs/continent_id_tiles/south_america_tiles.sqlite")
tiles_OC = terra::vect("D:/projects/dryland-GDEs/continent_id_tiles/oceania_tiles.sqlite")
tiles_EU = terra::vect("D:/projects/dryland-GDEs/continent_id_tiles/europe_tiles.sqlite")

# NA, AF, SA, OC, NA, EU
# North America ---- 

rds_EU = readr::read_rds(paste0("D:/projects/dryland-GDEs/summary_exports/GWS_GDE_area/", tiles_EU$name[1], "_gws_gde_area.rds"))
for (i in 2:nrow(tiles_EU)) {
  rds_EU = rbind(rds_EU, readr::read_rds(paste0("D:/projects/dryland-GDEs/summary_exports/GWS_GDE_area/", tiles_EU$name[i], "_gws_gde_area.rds")))
}
rds_EU = rds_EU |> group_by(z) |> summarize(area = sum(area, na.rm = T))
rds_EU$gws_bin = round(rds_EU$z / 1e3, 2)
rds_EU$gde = rds_EU$z - (rds_EU$gws_bin*1e3)
# area drying
a_dry = rds_EU |> filter(gws_bin <= 20 & gde == 1) |> pull(area) |> sum()/1e6
# all GDE area
a_all = rds_EU |> filter(gde == 1) |> pull(area) |> sum()/1e6
a_dry/a_all



