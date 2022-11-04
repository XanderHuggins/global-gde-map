library(here)
invisible(sapply(paste0(here("R/setup"), "/", list.files(here("R/setup"))), source)) 

# import all GDE areas

all_files = list.files("D:/projects/dryland-GDEs/summary_exports/PROT_GDE_area/", full.names = T)

df_all = readr::read_rds(all_files[1])

for (i in 2:length(all_files)) {
  df_all = rbind(df_all, readr::read_rds(all_files[i]))
}

df_all = df_all |> group_by(z) |> summarize(area = sum(area, na.rm = T))

df_all$prot = round(df_all$z / 1e3, 2)
df_all$gde = df_all$z - (df_all$prot*1e3)

# Calculate area of GDE in groundwater depletion regions
df_all |> filter(prot == 1 & gde == 1) |> pull(area) |> sum()/1e6
df_all |> filter(prot == 2 & gde == 1) |> pull(area) |> sum()/1e6
df_all |> filter(prot >= 1 & gde == 1) |> pull(area) |> sum()/1e6
