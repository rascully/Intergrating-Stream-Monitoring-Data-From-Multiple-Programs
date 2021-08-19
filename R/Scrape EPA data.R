#####Scraping EPA National Aquatic Resources data 

#This script is to pull data from the EPA data web page. Then we create a tidy data set from the 2004, 2008/09, 
#2013/14 NRSA stream data sets with the Macrioneverterbreate, physical habitat and water chemistry metric and 
#indicator data. The data set is then save to the GitHub page and the ScienceBase Item. 

download_EPA_NRSA <- function(SBUserName, SBPassword, CRS) {
  library(tidyverse)
  library(rvest)
  library(stringr)
  library(httr)
  library(sbtools)
  library(plyr)
  
  #####Sign into ScienceBase to find the link to the EPA data site 
  
  #SBUserName  <- readline(prompt="ScienceBase User Name: ")
  #SBPassword  <- readline(prompt="ScienceBase Password: ")
  
  authenticate_sb(SBUserName, SBPassword)
  sb_id<- "5ea9d6a082cefae35a21ba5a"
  
  ######Download all the data links from the EPA web site#####
  web_links<- item_get_fields(sb_id, "webLinks")
  content <- read_html(web_links[[1]]$uri)
  
  content <- read_html("https://www.epa.gov/national-aquatic-resource-surveys/data-national-aquatic-resource-surveys")
  
  tables <- content %>% 
    html_table(fill = TRUE) 
  
  EPA_table <- tables[[1]]
  
  ## Data links
  web <- content %>%
    html_nodes("table tr")%>%
    html_nodes(xpath="//td[3]") %>%  ## xpath
    html_nodes("a") %>%
    html_attr("href")
  
  EPA_table$web1 <- web  ## add files column
  
  ## metadata links accordingly
  web2 <- content %>%
    html_nodes("table tr") %>%
    html_nodes(xpath="//td[4]") %>%  ## xpath
    html_nodes("a") %>%
    html_attr("href")
  
  
  EPA_table[EPA_table$Metadata %in% "", "Metadata"] <- NA
  EPA_table[!is.na(EPA_table$Metadata), "web2"] <- web2
  
#####Sort out the NARS data from the full list of data sets on the EPA website#####
  NARS <- EPA_table %>% 
    filter(str_detect(Survey, "Streams"))
  
  
#####Create a location data table from the location data "WSA Verification - Data",  "External Data: Site Information - Data", 
                   #"NRSA 1314 Site Information - Data","NRSA 1819 Site Information - Data (CSV)")
  
 # location_data <- NARS %>% 
   # filter(str_detect(Indicator, "Site"))
  
  location_data <- NARS %>% 
    filter(str_detect(Indicator, "Site Information"))%>% 
    filter(!str_detect(web1,"ext")) %>% 
    filter(!str_detect(web1, "verification"))
  
for(i in 1:length(location_data$web1)) { 

    if (str_detect(location_data$Survey[i], "2004")) { 
      all_locations <- read.csv("./data/wsamarch2_2009/wsa_siteinfo_ts_final.csv")
      all_locations$DATE_COL <- as.Date(all_locations$DATE_COL, format="%m/%d/%Y")
      
      # 2004 data location column header don't match the other two data sets, need to check with the EPA to see if this data is comparable 
      all_locations <- all_locations %>% dplyr::rename(LON_DD83 = LON_DD, 
                                                       LAT_DD83= LAT_DD) 
      #Convert HUC  data to characters not integers 
      all_locations[str_detect(names(all_locations), "HUC")] <- all_locations %>% 
        dplyr::select(contains("HUC")) %>% 
        mutate_all(as.character) 
      
      all_locations[str_detect(names(all_locations), "VISIT_NO")] <- all_locations %>% 
        dplyr::select(contains("VISIT_NO")) %>% 
        mutate_all(as.character)
      
     } else { 
      print(location_data$Survey[i])
      url_link <- paste0("https://www.epa.gov", location_data$web1[i])
      temp_file <- tempfile(fileext = ".csv")
      download.file(url_link, temp_file)
      data2     <- read.csv(temp_file)
      
      #Convert the data from a string to a date 
      if (any(names(data2)=="DATE_COL")) { 
        if (grepl("-", data2$DATE_COL[1],  fixed=TRUE)) { 
          data2$DATE_COL <- as.Date(data2$DATE_COL, format= "%d-%B-%y")
        } else if (grepl("/", data2$DATE_COL[1],  fixed=TRUE)) { 
          data2$DATE_COL <- as.Date(data2$DATE_COL, format="%m/%d/%Y") 
        }
    }
      
      #convert data type to characters 
      data2[str_detect(names(data2), "HUC")] <- data2 %>% 
        dplyr::select(contains("HUC")) %>% 
        mutate_all(as.character)
      
      data2[str_detect(names(data2), "REACHCODE")] <- data2 %>% 
        dplyr::select(contains("REACHCODE")) %>% 
        mutate_all(as.character)
      
      data2[str_detect(names(data2), "STATECTY")] <- data2 %>% 
        dplyr::select(contains("STATECTY")) %>% 
        mutate_all(as.character)
      
      data2[str_detect(names(data2), "VISIT_NO")] <- data2 %>% 
        dplyr::select(contains("VISIT_NO")) %>% 
        mutate_all(as.character)
      
      if(any(str_detect(names(data2),"EPA_REG"))==T) {
        data2$EPA_REG <- as.character(data2$EPA_REG)
      } 
      all_locations     <- bind_rows(list(all_locations, data2))
      
      unlink(temp_file)
    }
   
} 
  
#Fill in blank years 
  blank_year             <- is.na(all_locations$YEAR)
  all_locations$YEAR[blank_year] <- format(all_locations$DATE_COL[blank_year],format="%Y")
  all_locations$YEAR<- as.integer(all_locations$YEAR)
  
#Check the longitude to make sure all are negative because this data set is all collected west of the prime meridian 
  if(any(all_locations$XLON_DD>0, na.rm=TRUE)== T) {
    postive_index <- all_locations$XLON_DD >0 & !is.na(all_locations$XLON_DD)
    all_locations$XLON_DD[postive_index] <- all_locations$XLON_DD[postive_index]*(-1)
  }
  
#####Build a water_chem data set####
  
  water_chem <-NARS %>% 
    filter(str_detect(Indicator, "Water Chemistry")) %>%  
    filter(str_detect(Data, "Indicator"))
  
# Build a table of all water chemestry data 
  for(wc in 1:length(water_chem$web1)){ 
    link = water_chem$web1[wc]
    url_link <- paste0("https://www.epa.gov", link)
    temp_file <- tempfile(fileext = ".csv")
    download.file(url_link, temp_file)
    data_set<- read.csv(temp_file)
    
    data_set[str_detect(names(data_set), "VISIT_NO")] <- data_set %>% 
      dplyr::select(contains("VISIT_NO")) %>% 
      mutate_all(as.character)
    
    data_set[str_detect(names(data_set), "LDCBF_G08")] <- data_set %>% 
      dplyr::select(contains("LDCBF_G08")) %>% 
      mutate_all(as.double)
    
    data_set[str_detect(names(data_set), "L_RRPW3")] <- data_set %>% 
      dplyr::select(contains("L_RRPW3")) %>% 
      mutate_all(as.double)
  
    if (wc==1) {
      name <- "data_water_chem"
      assign(name, data_set)
      data_water_chem$DATE_COL <- as.Date(data_water_chem$DATE_COL, format= "%d-%B-%y")
    } else {
      data_set$DATE_COL <- as.Date.character(data_set$DATE_COL, format="%m/%d/%Y")
      data_water_chem <- bind_rows(data_water_chem, data_set)
    }
    
    unlink(temp_file)
  } 
  
  if (any(is.na(data_water_chem$YEAR))==T) {
    data_water_chem <- mutate(data_water_chem, YEAR = as.integer(format(data_water_chem$DATE_COL,format="%Y")))
  }
  

#####Build a data table of the physical habitat data #####
  
  phys_hab <-NARS %>% 
    filter(str_detect(Indicator, "Physical Habitat")) %>%  
    filter(str_detect(web1, paste(c("phabmet", "physical_habitat","phabmed" , "nrsa1314_phabmed"), collapse = "|"))) 
  
 phys_hab2004 <- phys_hab %>% 
        filter(str_detect(Survey, "2004")) 
 
 for(ph2004 in 1:length(phys_hab2004$web1)) {
   link = phys_hab2004$web1[ph2004]
   url_link <- paste0("https://www.epa.gov", link)
   temp_file <- tempfile(fileext = ".csv")
   download.file(url_link, temp_file)
 
    if (ph2004 ==1 ) { 
         data_set2004<- read.csv(temp_file)
         
    } else { 
      data_set20042 <- read.csv(temp_file)
      data_phys_hab  <- full_join(data_set2004, data_set20042)
      data_phys_hab <-data_phys_hab %>% 
        mutate(UID = paste0(SITE_ID, "-", VISIT_NO))
      
      # convert visit number to string to accommodate "R" in 2021 data release 
      data_phys_hab[str_detect(names(data_phys_hab), "VISIT_NO")] <- data_phys_hab %>% 
        dplyr::select(contains("VISIT_NO")) %>% 
        mutate_all(as.character)
      
      data_phys_hab[str_detect(names(data_phys_hab), "LDCBF_G08")] <- data_phys_hab %>% 
        dplyr::select(contains("LDCBF_G08")) %>% 
        mutate_all(as.character)
      
      data_phys_hab[str_detect(names(data_phys_hab), "L_RRPW3")] <- data_phys_hab %>% 
        dplyr::select(contains("L_RRPW3")) %>% 
        mutate_all(as.character)
      
    }
  
  } 
 
phys_hab <- phys_hab %>% 
              filter(!str_detect(phys_hab$Survey, "2004"))
 
  for(ph in 1:length(phys_hab$web1)){ 
  
    link = phys_hab$web1[ph]
    url_link <- paste0("https://www.epa.gov", link)
    temp_file <- tempfile(fileext = ".csv")
    download.file(url_link, temp_file)
    data_set<- read.csv(temp_file)
   
#Convert variables to match types across all data sets 
    
    data_set[str_detect(names(data_set), "VISIT_NO")] <- data_set %>% 
      dplyr::select(contains("VISIT_NO")) %>% 
      mutate_all(as.character)
    
    data_set[str_detect(names(data_set), "LDCBF_G08")] <- data_set %>% 
      dplyr::select(contains("LDCBF_G08")) %>% 
      mutate_all(as.character)
    
    data_set[str_detect(names(data_set), "L_RRPW3")] <- data_set %>% 
      dplyr::select(contains("L_RRPW3")) %>% 
      mutate_all(as.character)
    
    data_set[str_detect(names(data_set), "UID")] <- data_set %>% 
      dplyr::select(contains("UID")) %>% 
      mutate_all(as.character)
 

    #Convert the data from a string to a date 
    if (any(names(data_set)=="DATE_COL")) { 
      if (grepl("-", data_set$DATE_COL[1],  fixed=TRUE)) { 
        data_set$DATE_COL <- as.Date(data_set$DATE_COL, format= "%d-%B-%y")
      } else if (grepl("/", data_set$DATE_COL[1],  fixed=TRUE)) { 
        data_set$DATE_COL <- as.Date(data_set$DATE_COL, format="%m/%d/%Y") 
      }
    }
      data_phys_hab <- bind_rows(data_phys_hab, data_set)
      unlink(temp_file)
  }
  
test_ID = "WAZP99-0539"

  data_phys_hab[data_phys_hab$UID == "10001",] %>% 
    select(contains(c("SITE_ID", "UID", "LAT", "LON", "VISIT_NO", "DATE_COL")))
  
    
  #join the water chem and the phys habitat data  
  dataset <- full_join(data_phys_hab, data_water_chem, by= c("SITE_ID", "VISIT_NO","YEAR"))  
  
  data_phys_hab[data_phys_hab$SITE_ID == test_ID,] %>% 
    select(contains(c("SITE_ID","UID",  "LAT", "LON", "VISIT_NO", "DATE_COL")))
  
  data_water_chem[data_water_chem$SITE_ID == test_ID,] %>% 
    select(contains(c("SITE_ID", "UID","LAT", "LON", "VISIT_NO", "DATE_COL")))

  dataset[dataset$SITE_ID == test_ID,] %>% 
    select(contains(c("SITE_ID", "UID","LAT", "LON", "VISIT_NO")))
  
#remove columns with .y indicating duplicate columns 
  dataset<- dataset %>% 
   dplyr::select(-contains(c(".y", "x.x", "y.y")))
  
#Rename columns with .x, so that field names match the original fields in the metadata 
  names(dataset) <- str_remove(names(dataset), ".x")
  
  all_locations[all_locations$SITE_ID == test_ID,] %>% 
    select(contains(c("SITE_ID", "UID", "LAT", "LON", "VISIT_NO")))
  
#join data and locations 
  ##dataset_locations <- full_join(dataset, all_locations, by = c("SITE_ID", "VISIT_NO", "DATE_COL"))
  
  dataset_locations <- dataset %>% 
                      inner_join(all_locations, by = c("SITE_ID", "VISIT_NO")) 
 
 all_locations[all_locations$SITE_ID == test_ID,] %>% 
    select(contains(c("SITE_ID", "LAT", "LON", "VISIT_NO", "DATE_COL")))
 
 dataset[dataset$SITE_ID == test_ID,] %>% 
   select(contains(c("SITE_ID", "LAT", "LON", "VISIT_NO", "DATE_COL")))
 
 dataset_locations[dataset_locations$SITE_ID == test_ID,] %>% 
   select(contains(c("SITE_ID", "LAT", "LON", "VISIT_NO", "DATE_COL")))  
   
 #####Fill in columns where data exists 
   x <- dataset_locations %>% select(contains(".x"))
   duplicate_names <- str_remove(names(x), ".x")
   y <- dataset_locations %>% 
      select(matches(duplicate_names)) %>% 
      select(contains(".y"))

# remove duplicate names from the joined data set 

 for(name_index in duplicate_names) {  
    
     name_index_x <- paste0(name_index, ".x")
     na_index     <- is.na(dataset_locations[[name_index_x]])    
     name_index_y <- paste0(name_index, ".y")
    
     if (any(na_index)) {
       dataset_locations[[name_index_x]][na_index] <- dataset_locations[[name_index_y]][na_index]
     } 
     
    } 
   
  #####Fill in year when possible#####
  if (any(is.na(dataset_locations$YEAR))) {
      dataset_locations <- mutate(dataset_locations, YEAR = as.integer(format(dataset_locations$DATE_COL,format="%Y")))
  }
  
  #remove columns with .y indicating duplicate columns 
  dataset_locations<- dataset_locations %>% 
    dplyr::select(-contains(c(".y", "x.x", "y.y")))
  
  #Rename columns with .x, so that field names match the original fields in the metadata 
  names(dataset_locations) <- str_remove(names(dataset_locations), ".x")
  
  #Add a date the data was downloaded and combined and the program
  dataset_locations <- dataset_locations %>% 
    mutate(DATE_COMBIND = Sys.Date()) %>% 
    mutate(PROGRAM = "NRSA") 
  
  
# Check the combind datasets for duplicate UIDs (eventIDs)
  dupl_UID <- dataset_locations %>% 
              filter(duplicated(UID)) 
  
  index <- str_detect(dataset_locations$UID, paste(c(dupl_UID$UID), collapse = "|"))
  
#Replace the duplicate UIDs with a contaoncination of the UID and the data the data was collected 
  
  dataset_locations$UID[index] = paste0(dataset_locations$UID[index], "-", dataset_locations$DATE_COL[index])
  
  all_locations[all_locations$SITE_ID == test_ID,] %>% 
        select(contains(c("SITE_ID", "UID", "LAT", "LON", "VISIT_NO")))
  
#Delete the old EPA data file 
  files <- list.files(paste0(getwd(), "/data"))
  files_remove <- paste0(getwd(), "/data/", files[str_detect(files, "NRSA")])
  file.remove(files_remove)
  
  #####Save the Tidy Data set to Sciencebase#####
  short_name = paste0("Tidy_NRSA_Data_Set.csv")
  file_name <- paste0("data/", short_name)
  write.csv(dataset_locations, file=file_name)
  
  if(any(str_detect(item_list_files(sb_id)$fname, short_name))){
    item_replace_files(sb_id, file_name, title="")
  } else {
    item_append_files(sb_id, file_name)
  }
  
  ##### Update the last Processed date to indicate the last time the code was run. 
  sb_dates <- item_get_fields(sb_id, c('dates'))
  sb_dates[[1]][["dateString"]] <- as.character(Sys.Date())
  
  # This does not work? No error message? Don't understand the issue? 
  items_update(sb_id, info = list(dates = sb_dates)) 
  
  return(dataset_locations)
}
  