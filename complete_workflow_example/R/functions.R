
# A function to prep and join two datasets, fDOM from water quality with
# continuous discharge
combine_fdom_csd <- function(neon_waq, neon_csd){
  
  # Downstream position
  waq_down <- neon_waq %>%
    filter(horizontalPosition == "102")
  
  # Isolate the columns containing Fluorescent Dissolved Organic Matter (fDOM) data
  # and remove any with quality flags, then round to make joining with CSD easier
  fdom <- waq_down %>%
    select(endDateTime, contains("fDOM")) %>%
    filter(fDOMFinalQF == 0) %>%
    mutate(endDateTime = round_date(endDateTime, unit = "1 minute"))
  
  # Remove quality flags and then round
  csd <- neon_csd %>%
    filter(dischargeFinalQF == 0) %>%
    mutate(endDate = round_date(endDate, unit = "1 minute"))
  
  # Join the datasets, subset to dates of high flow events
  fdom_csd <- inner_join(x = fdom,
                         y = csd, 
                         by = c("endDateTime" = "endDate")) %>%
    filter(endDateTime > "2022-04-21",
           endDateTime < "2022-04-25")
  
  return(fdom_csd)
  
}


# A function to prep and join two datasets, nitrate in surface water with
# continuous discharge. This matches values every 15 minutes, but an alternative
# would be to use 15-minute averages
combine_nsw_csd <- function(neon_nsw, neon_csd){
  
  # Remove data with quality flags, then round to make joining with CSD easier
  nsw <- neon_nsw %>%
    filter(finalQF == 0) %>%
    mutate(endDateTime = round_date(endDateTime, unit = "1 minute"))
  
  # Remove quality flags and then round
  csd <- neon_csd %>%
    filter(dischargeFinalQF == 0) %>%
    mutate(endDate = round_date(endDate, unit = "1 minute"))
  
  # Join the datasets (every 15 min. the times will match up), subset to dates
  # of high flow events
  nsw_csd <- inner_join(x = nsw,
                        y = csd,
                        by = c("endDateTime" = "endDate")) %>%
    filter(endDateTime > "2022-04-21",
           endDateTime < "2022-04-25")
  
  return(nsw_csd)
  
}


