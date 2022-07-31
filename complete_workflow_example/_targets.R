
# Load packages required to define the pipeline:
library(targets)
library(tarchetypes)

# Set target options:
tar_option_set(
  # Packages that your targets need to run
  packages = c("tidyverse"),
  # Default storage format
  format = "rds"
)

# Load the R script with your custom functions:
source("R/functions.R")

# Define the targets in the workflow:
list(
  tar_target(name = neon_waq,
             command = {
               # Download the water quality dataset for COMO
               waq <- loadByProduct(dpID = "DP1.20288.001", 
                                    site = "COMO", 
                                    startdate = "2022-04", 
                                    enddate = "2022-04", 
                                    package = "expanded",
                                    release = "current",
                                    token = Sys.getenv("NEON_TOKEN"),
                                    check.size = F)
               
               # Isolate the table of interest
               return(waq$waq_instantaneous)
             },
             packages = c("tidyverse", "neonUtilities")),
  
  # Nitrate in surface water
  tar_target(name = neon_nsw,
             command = {
               # Download the nitrate dataset for COMO
               nsw <- loadByProduct(dpID = "DP1.20033.001", 
                                    site = "COMO", 
                                    startdate = "2022-04", 
                                    enddate = "2022-04", 
                                    package = "expanded",
                                    release = "current",
                                    token = Sys.getenv("NEON_TOKEN"),
                                    check.size = F)
               
               # Isolate the table of interest
               return(nsw$NSW_15_minute)
             },
             packages = c("tidyverse", "neonUtilities")),
  
  # Continuous discharge
  tar_target(name = neon_csd,
             command = {
               # Download the continuous discharge dataset for COMO
               csd <- loadByProduct(dpID = "DP4.00130.001", 
                                    site = "COMO", 
                                    startdate = "2022-04", 
                                    enddate = "2022-04", 
                                    package = "expanded",
                                    release = "current",
                                    token = Sys.getenv("NEON_TOKEN"),
                                    check.size = F)
               
               # Isolate the table of interest
               return(csd$csd_continuousDischarge)
             },
             packages = c("tidyverse", "neonUtilities")),
  
  # Join CSD with fDOM from water quality
  tar_target(combined_fdom_csd,
             combine_fdom_csd(neon_waq, neon_csd),
             packages = c("tidyverse", "lubridate")),
  
  # Join CSD with NSW
  tar_target(combined_nsw_csd,
             combine_nsw_csd(neon_nsw, neon_csd),
             packages = c("tidyverse", "lubridate")),
  
  # Plot fDOM C-Q plot
  tar_target(fdom_cq_plot,
             {
               # C-Q plot: lighter color = more recent (closer to April 25th)
               ggplot(data = combined_fdom_csd) +
                 geom_point(aes(x = maxpostDischarge,
                                y = fDOM,
                                color = endDateTime)) +
                 ggtitle("COMO fDOM vs. Q") +
                 xlab("Q (L/s)") +
                 ylab("fDOM (QSU)") +
                 scale_color_viridis_c() +
                 theme_bw() +
                 theme(legend.position = "none")
             }),
  
  # Plot NSW C-Q plot
  tar_target(nsw_cq_plot,
             {
               # C-Q plot: lighter color = more recent (closer to April 25th)
               ggplot(data = combined_nsw_csd) +
                 geom_point(aes(x = maxpostDischarge,
                                y = surfWaterNitrateMean,
                                color = endDateTime)) +
                 ggtitle("COMO NO3-N vs. Q (subset)") +
                 xlab("Q (L/s)") +
                 ylab("NO3-N (uM)") +
                 # Another option
                 # ylab(expression(NO[3]("\U00B5"*M))) +
                 scale_color_viridis_c() +
                 theme_bw() +
                 theme(legend.position = "none")
             }),
  
  tar_render(output_report,
             # Path to the R Markdown file to knit
             path = "output_report.Rmd",
             # If you need specific packages
             packages = c("kableExtra", "tidyverse"))
)
