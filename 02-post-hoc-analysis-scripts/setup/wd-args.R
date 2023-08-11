# Name: wd-args.R
# Description: Set working directories

wd = here()

# Set temporary terra directory to external disk with storage availability
terraOptions(tempdir = "D://Geodatabase/Rtemp")

cus_theme = theme(panel.background = element_rect(fill = "transparent"),
                  plot.background = element_rect(fill = "transparent", colour = NA),
                  panel.grid = element_blank(),
                  axis.line = element_line(color = "black"), 
                  panel.ontop = TRUE, legend.position = "none")