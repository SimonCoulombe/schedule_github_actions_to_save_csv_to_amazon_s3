# the geocode_and_qa.R file is the file that can be run in one go on the docker container when logged into the rstudio server.
# because we need to wait while the python scripts run 
# processx allows us to do it, but it  doesnt seem to work very well on github actions,
# so I split this script  into multiple files  (prep_geocode, clean_after_geocode, prep_qa, clean_after_qa)


library(dplyr)
library(readr)
library(janitor)
library(processx)
#library(reticulate)
#use_condaenv(condaenv = "gwells_locationqa", required= TRUE)

#list.files("python")

max_number_geocoded <- 50
max_number_qa <- 1000

#system("git clone https://github.com/SimonCoulombe/gwells_geocode_and_archive_data.git")
source("R/col_types_wells.R")


p <- process$new(command = "python/download.sh")
## downloading takes about 3 minutes
i <- 1
while(p$is_alive()){
  print(paste0("Waiting for downloads to complete. Total wait = ",  i, " s" ))
  i <- i + 1
  Sys.sleep(1)
}


# lubridate can return time given a specific time zone.
lubridate::with_tz(Sys.time(), "America/Vancouver")

# voici la date de vancouver
as.Date(Sys.time() , tz = "America/Vancouver")



current_well <- read_csv("data/wells.csv"
                         , col_types = col_types_wells # from R/coltypes_we
)

if(FALSE){
  gwells_data_first_appearance <- current_well %>% head(120000) %>%
    mutate(date_added = Sys.Date() - (max(well_tag_number)-well_tag_number)/ 1000)
} else{
  gwells_data_first_appearance <-
    read_csv("https://raw.githubusercontent.com/SimonCoulombe/gwells_geocode_and_archive_data/main/data/gwells_data_first_appearance.csv",
             col_types = col_types_wells)
}

#------------------------------------------------------------
# Update historical list of wells on the day they were added
#------------------------------------------------------------

new_wells <- current_well %>%
  anti_join(gwells_data_first_appearance %>% select(well_tag_number)) %>%
  mutate(date_added = as.Date(Sys.time() , tz = "America/Vancouver"))


# this is our  new list of date added, overwrite the old one
gwells_data_first_appearance <-
  bind_rows(gwells_data_first_appearance, new_wells)
write_csv(gwells_data_first_appearance, "data/gwells_data_first_appearance.csv")


# this is the list of well_tag_number in the csv today, might be useful to rebuild the list of dates added on day
# it would be nice to save all the data each day, but 50 MB is too heavy for us..
well_tags_in_current_wells <-current_well  %>% select(well_tag_number)
write_csv(well_tags_in_current_wells, paste0("data/well_tag_numbers_",format(as.Date(Sys.time() , tz = "America/Vancouver"), "%Y%m%d")  ,".csv"))
zip(paste0("data/well_tag_numbers_",format(as.Date(Sys.time() , tz = "America/Vancouver"), "%Y%m%d")  ,".zip"),
    paste0("data/well_tag_numbers_",format(as.Date(Sys.time() , tz = "America/Vancouver"), "%Y%m%d")  ,".csv")
)


#------------------------------------------------------------
# geocode wells that have never been geocoded
#------------------------------------------------------------

geocoded <- read_csv("https://raw.githubusercontent.com/SimonCoulombe/gwells_geocode_and_archive_data/main/data/wells_geocoded.csv")

# ici on détermine ce qui doit être géocodé (ie, on a jamais *géotaggé*  ton well_tag_number)

to_geocode <- current_well %>%
  anti_join(geocoded %>% select(well_tag_number)) %>%
  tail(max_number_geocoded)

# geocoding takes about 1 second per row
if(nrow(to_geocode)> 0){
  write.csv(to_geocode, "data/wells.csv")

  p <- process$new(command = "python/geocode.sh")
  i <- 1
  while(p$is_alive()){
    print(paste0("Waiting for geocode to complete. Total wait = ",  i, " s" ))
    i <- i + 1
    Sys.sleep(1)
  }
}
newly_geocoded <- read_csv("data/wells_geocoded.csv")
all_geocoded <-
  bind_rows(geocoded, newly_geocoded)

write_csv(all_geocoded, "data/wells_geocoded.csv")
#------------------------------------------------------------
# qa  wells that have never been geocoded
#------------------------------------------------------------

old_qa  <- read_csv("https://raw.githubusercontent.com/SimonCoulombe/gwells_geocode_and_archive_data/main/data/gwells_locationqa.csv") %>%
  select(-one_of(c("Unnamed: 0")))


to_qa_geocoded <- all_geocoded %>%
  anti_join(old_qa %>% select(well_tag_number)) %>%
  tail(max_number_qa)



# this takes 800 seconds (12 minutes) on 5 rows..
if(nrow(to_qa_geocoded)> 0){
  write.csv(to_qa_geocoded, "data/wells_geocoded.csv")
  to_qa_wells <- gwells_data_first_appearance %>%
    inner_join(to_qa_geocoded %>% select(well_tag_number))
  to_qa_wells <- gwells_data_first_appearance %>%
    inner_join(to_qa_geocoded %>% select(well_tag_number))
  write.csv(to_qa_wells, "data/wells.csv")

  system("cp /GWELLS_LocationQA/data/esa_bc.tif  data") #  no permission to cp..
  p <- process$new(command = "python/qa.sh")
  i <- 1
  while(p$is_alive()){
    print(paste0("Waiting for QA to complete. Total wait = ",  i, " s" ))
    i <- i + 1
    Sys.sleep(1)
  }

  new_qa <- read_csv("gwells_locationqa.csv") %>%
    select(-one_of(c("Unnamed: 0")))

  all_qa <- bind_rows(old_qa, new_qa)

  write_csv(all_qa, "data/gwells_locationqa.csv")
}
