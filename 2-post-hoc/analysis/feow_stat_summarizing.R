library(here)
invisible(sapply(paste0(here("R/setup"), "/", list.files(here("R/setup"))), source)) 

# import all GDE areas

all_files = list.files("D:/projects/dryland-GDEs/summary_exports/FEOW_GDE_area/", full.names = T)

df_all = readr::read_rds(all_files[1])

for (i in 2:length(all_files)) {
  df_all = rbind(df_all, readr::read_rds(all_files[i]))
}

df_all = df_all |> group_by(z) |> summarize(area = sum(area, na.rm = T))

df_all$feow = round(df_all$z / 1e3, 2)
df_all$gde = df_all$z - (df_all$feow*1e3)

feow_df = data.frame(
  feow_id = unique(df_all$feow),
  gde_area = rep(NA),
  incl_area = rep(NA)
)

for (i in 1:nrow(feow_df)) {
  feow_id = feow_df$feow_id[i]
  feow_df$gde_area[i] = df_all |> dplyr::filter(feow == feow_id & gde == 1) |> pull(area) |> sum(na.rm = T)
  feow_df$incl_area[i]  = df_all |> dplyr::filter(feow == feow_id & gde >= 1)  |> pull(area) |> sum(na.rm = T)
}

feow_df$gde_frac = feow_df$gde_area/feow_df$incl_area
feow_df$gde_frac[feow_df$incl_area == 0] = NA

# Merge data with GWS trend containing shapefile
feow_v = terra::vect("D:/projects/dryland-GDEs/additional_data/feow_gws_trends.sqlite")
feow_v = merge(x = feow_v, y = feow_df, by.x = "eco_id", by.y = "feow_id")

# Create a feow with only GDEs considered
feow_v = feow_v[feow_v$gde_frac >= 0]

# Create a few with no arid regions
feow_NA = feow_v[is.na(feow_v$gde_frac)]

# writeVector(x = feow_v,
#             filename = "D:/projects/dryland-GDEs/additional_data/feow_v_gde_frac.sqlite",
#             filetype = "SQlite", overwrite = T)
# 
# writeVector(x = feow_NA,
#             filename = "D:/projects/dryland-GDEs/additional_data/feow_v_gde_frac_NA.sqlite",
#             filetype = "SQlite", overwrite = T)


# 
feow_v$colorId <- rep(NA) 
feow_v$colorId[feow_v$gws_mean <= 0 & feow_v$gde_frac >= 0.5] <- 1
feow_v$colorId[feow_v$gws_mean <= 0 & feow_v$gde_frac <  0.5] <- 2
feow_v$colorId[feow_v$gws_mean > 0  & feow_v$gde_frac >= 0.5] <- 3
feow_v$colorId[feow_v$gws_mean > 0  & feow_v$gde_frac <  0.5] <- 4

aa = 0.5
ggplot(data = feow_v |> as.data.frame(), 
       aes(x = 100*gws_mean, y = 100*gde_frac, size = gde_area, fill = as.factor(colorId), label = eco_id)) +
  annotate("rect", xmin=-Inf,  xmax=0,  ymin=50, ymax=100, fill="#F35926", alpha=aa) +
  annotate("rect", xmin=-Inf,  xmax=0,  ymin=0,  ymax=50,  fill="#FFCC80", alpha=aa) +
  annotate("rect", xmin=0,   xmax=Inf,  ymin=50, ymax=100, fill="#7b67ab", alpha=aa) +
  annotate("rect", xmin=0,   xmax=Inf,  ymin=0,  ymax=50,  fill="#c3b3d8", alpha=aa) +
  geom_point(shape = 21) +
  geom_text()+
  # scale_fill_manual(values = c('#804D36', '#C7B448', "#9771B4", '#E8E8E8')) +
  scale_fill_manual(values = c('#F35926', #upper left 
                               '#FFCC80', #lower left
                               "#7b67ab", #upper right
                               '#c3b3d8')) + #lower right
  geom_vline(xintercept = 0) +
  geom_vline(xintercept = 2) +
  geom_hline(yintercept = 0) +
  geom_hline(yintercept = 100) +
  cus_theme +
  coord_cartesian(xlim = c(-2, 2), ylim = c(0,100), clip = "on", expand = 0)

ggsave(filename = "D:/projects/dryland-GDEs/plots/feow_scatter.png",
       plot = last_plot(), 
       device = "png",
       width = 100,
       height = 60,
       units = "mm")

writeVector(x = feow_v,
            filename = "D:/projects/dryland-GDEs/additional_data/feow_bivar.sqlite",
            filetype = "SQlite", overwrite = T)
