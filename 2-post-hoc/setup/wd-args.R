# Name: wd-args.R
# Description: Set working directories

wd = here()

# Set temporary terra directory to external disk with storage availability
terraOptions(tempdir = "D://Geodatabase/Rtemp")