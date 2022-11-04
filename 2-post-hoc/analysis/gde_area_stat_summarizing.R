library(here)
invisible(sapply(paste0(here("R/setup"), "/", list.files(here("R/setup"))), source)) 

# import all GDE areas

all_files = list.files("D:/projects/dryland-GDEs/summary_exports/GDE_area/", full.names = T)

df_all = readr::read_rds(all_files[1])

for (i in 2:length(all_files)) {
  df_all = rbind(df_all, readr::read_rds(all_files[i]))
}

df_all = df_all |> group_by(z) |> summarize(area = sum(area, na.rm = T))

gde = df_all |> filter(z == 1) |> pull(area) |> sum()/1e6 # 5.26 
all_dryland = df_all |> filter(z >= 1) |> pull(area) |> sum()/1e6 # 23.C04
all_area = df_all |> filter(z >= 0) |> pull(area) |> sum()/1e6 # 23.C04
gde/all_dryland #22.3%

# now create histogram of GDE area per world region
tiles_NA = terra::vect("D:/projects/dryland-GDEs/continent_id_tiles/north_america_tiles.sqlite")
tiles_SA = terra::vect("D:/projects/dryland-GDEs/continent_id_tiles/south_america_tiles.sqlite")
tiles_EU = terra::vect("D:/projects/dryland-GDEs/continent_id_tiles/europe_tiles.sqlite")
tiles_AF = terra::vect("D:/projects/dryland-GDEs/continent_id_tiles/africa_tiles.sqlite")
tiles_AS= terra::vect("D:/projects/dryland-GDEs/continent_id_tiles/asia_tiles.sqlite")
tiles_OC = terra::vect("D:/projects/dryland-GDEs/continent_id_tiles/oceania_tiles.sqlite")

# filter rds files based on world region membership
rds_NA = readr::read_rds(paste0("D:/projects/dryland-GDEs/summary_exports/GDE_area/", tiles_NA$name[1], "_gde_area.rds"))
for (i in 2:nrow(tiles_NA)) {
  rds_NA = rbind(rds_NA, readr::read_rds(paste0("D:/projects/dryland-GDEs/summary_exports/GDE_area/", tiles_NA$name[i], "_gde_area.rds")))
}

rds_SA = readr::read_rds(paste0("D:/projects/dryland-GDEs/summary_exports/GDE_area/", tiles_SA$name[1], "_gde_area.rds"))
for (i in 2:nrow(tiles_SA)) {
  rds_SA = rbind(rds_SA, readr::read_rds(paste0("D:/projects/dryland-GDEs/summary_exports/GDE_area/", tiles_SA$name[i], "_gde_area.rds")))
}

rds_EU = readr::read_rds(paste0("D:/projects/dryland-GDEs/summary_exports/GDE_area/", tiles_EU$name[1], "_gde_area.rds"))
for (i in 2:nrow(tiles_EU)) {
  rds_EU = rbind(rds_EU, readr::read_rds(paste0("D:/projects/dryland-GDEs/summary_exports/GDE_area/", tiles_EU$name[i], "_gde_area.rds")))
}

rds_AF = readr::read_rds(paste0("D:/projects/dryland-GDEs/summary_exports/GDE_area/", tiles_AF$name[1], "_gde_area.rds"))
for (i in 2:nrow(tiles_AF)) {
  rds_AF = rbind(rds_AF, readr::read_rds(paste0("D:/projects/dryland-GDEs/summary_exports/GDE_area/", tiles_AF$name[i], "_gde_area.rds")))
}

rds_AS = readr::read_rds(paste0("D:/projects/dryland-GDEs/summary_exports/GDE_area/", tiles_AS$name[1], "_gde_area.rds"))
for (i in 2:nrow(tiles_AS)) {
  rds_AS = rbind(rds_AS, readr::read_rds(paste0("D:/projects/dryland-GDEs/summary_exports/GDE_area/", tiles_AS$name[i], "_gde_area.rds")))
}

rds_OC = readr::read_rds(paste0("D:/projects/dryland-GDEs/summary_exports/GDE_area/", tiles_OC$name[1], "_gde_area.rds"))
for (i in 2:nrow(tiles_OC)) {
  rds_OC = rbind(rds_OC, readr::read_rds(paste0("D:/projects/dryland-GDEs/summary_exports/GDE_area/", tiles_OC$name[i], "_gde_area.rds")))
}

# Now summarize each one
rds_NA = rds_NA |> group_by(z) |> summarize(area = sum(area, na.rm = T))
rds_NA$name = "NA"
rds_SA = rds_SA |> group_by(z) |> summarize(area = sum(area, na.rm = T))
rds_SA$name = "SA"
rds_EU = rds_EU |> group_by(z) |> summarize(area = sum(area, na.rm = T))
rds_EU$name = "EU"
rds_AF = rds_AF |> group_by(z) |> summarize(area = sum(area, na.rm = T))
rds_AF$name = "AF"
rds_AS = rds_AS |> group_by(z) |> summarize(area = sum(area, na.rm = T))
rds_AS$name = "AS"
rds_OC = rds_OC |> group_by(z) |> summarize(area = sum(area, na.rm = T))
rds_OC$name = "OC"

rds_all = rbind(rds_NA, rds_SA, rds_EU, rds_AF, rds_AS, rds_OC)
rds_all |> group_by(z) |> summarize(area = sum(area, na.rm = T)) |> filter(z == 1) |> pull(area) |> sum()/1e6
rds_all |> group_by(z) |> summarize(area = sum(area, na.rm = T)) |> filter(z == 2) |> pull(area) |> sum()/1e6

rds_all %<>% filter(z >= 1)
rds_all$z %<>% factor(levels = c('2', '1'))
rds_all$name %<>% as.factor()
rds_all$name %<>% factor(levels = c('AS', 'AF', 'SA', 'OC', 'NA', 'EU'))

pct_df = data.frame(name = unique(rds_all$name))
pct_df$pct[pct_df$name == "NA"] = rds_NA |> filter(z == 1) |> pull(area) |> sum() / rds_NA |> filter(z >= 1) |> pull(area) |> sum()
pct_df$pct[pct_df$name == "SA"] = rds_SA |> filter(z == 1) |> pull(area) |> sum() / rds_SA |> filter(z >= 1) |> pull(area) |> sum()
pct_df$pct[pct_df$name == "EU"] = rds_EU |> filter(z == 1) |> pull(area) |> sum() / rds_EU |> filter(z >= 1) |> pull(area) |> sum()
pct_df$pct[pct_df$name == "AF"] = rds_AF |> filter(z == 1) |> pull(area) |> sum() / rds_AF |> filter(z >= 1) |> pull(area) |> sum()
pct_df$pct[pct_df$name == "AS"] = rds_AS |> filter(z == 1) |> pull(area) |> sum() / rds_AS |> filter(z >= 1) |> pull(area) |> sum()
pct_df$pct[pct_df$name == "OC"] = rds_OC |> filter(z == 1) |> pull(area) |> sum() / rds_OC |> filter(z >= 1) |> pull(area) |> sum()

pct_df$name %<>% as.factor()
pct_df$name %<>% factor(levels = c('AS', 'AF', 'SA', 'OC', 'NA', 'EU'))

cus_theme = theme(panel.background = element_rect(fill = "transparent"),
                  plot.background = element_rect(fill = "transparent", colour = NA),
                  panel.grid = element_blank(),
                  axis.line = element_line(color = "black"), 
                  panel.ontop = TRUE, legend.position = "none")

ggplot(data = rds_all, aes(x = name, y = area, fill = z)) +
  geom_bar(position = "stack", stat = "identity", col = "black") +
  # coord_trans(y = "log10") +
  # coord_cartesian(expand = 0) +
  scale_fill_manual(values = c('#F8BF66', '#1B960A')) +
  cus_theme + theme(plot.margin = unit(c(2,5,2,2), "mm"))
  # geom_point(data = pct_df, aes(x = name, y = pct), stat = "identity")
  # scale_y_continuous(
  #   
  #   # Features of the first axis
  #   name = "Temperature (Celsius °)",
  #   
  #   # Add a second axis and specify its features
  #   sec.axis = sec_axis(~.*coeff, name="Price ($)")
  # ) 
  

ggsave(filename = "D:/projects/dryland-GDEs/plots/gde_area_continents.png",
       plot = last_plot(), 
       device = "png",
       width = 100,
       height = 60,
       units = "mm")
