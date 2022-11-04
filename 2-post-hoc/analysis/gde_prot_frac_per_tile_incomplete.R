library(here)
invisible(sapply(paste0(here("R/setup"), "/", list.files(here("R/setup"))), source)) 

# join tile summaries to 

all_files_f = list.files("D:/projects/dryland-GDEs/summary_exports/GDE_area/", full.names = T)
all_files_s = list.files("D:/projects/dryland-GDEs/summary_exports/GDE_area/", full.names = F)
all_files_ss = gsub("_gde_area.rds", "", all_files_s)

# import vector file
tile_v = terra::vect("D:/Geodatabase/GDEs/v4_tile_vector_extents/all_tile_extents.sqlite")
tile_v$protpct = rep(NA)

for (i in 1:length(all_files_ss)) {
  # i = 1
  tile_name = all_files_ss[i]
  
  # import overall GDE area summary
  gde_area = readr::read_rds(paste0("D:/projects/dryland-GDEs/summary_exports/GDE_area/", all_files_ss[i], "_gde_area.rds"))
  gde_area = gde_area |> filter(z == 1) |> pull(area) |> sum()
  
  prot_area = 0
  
  # import protected area summary, if it exists
  if (file.exists(paste0("D:/projects/dryland-GDEs/summary_exports/PROT_GDE_area/", all_files_ss[i], "_prot_gde_area.rds"))) {
    prot_area = readr::read_rds(paste0("D:/projects/dryland-GDEs/summary_exports/PROT_GDE_area/", all_files_ss[i], "_prot_gde_area.rds"))
    prot_area = prot_area |> group_by(z) |> summarize(area = sum(area, na.rm = T))
    prot_area$prot = round(prot_area$z / 1e3, 2)
    prot_area$gde = prot_area$z - (prot_area$prot*1e3)
    prot_area = prot_area |> filter(prot >= 1 & gde == 1) |> pull(area) |> sum()
  }
  
  tile_v$protpct[tile_v$name == all_files_ss[i]] = prot_area/gde_area
}

tile_v$protpct = round(as.numeric(tile_v$protpct), 2)
tile_v$protpct[is.nan(tile_v$protpct)] = 0

writeVector(x = tile_v,
            filename = "D:/projects/dryland-GDEs/additional_data/tile_protected_pct_nona.sqlite",
            filetype = "SQlite", overwrite = T)
