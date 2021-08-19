#####Using the data exchange specifications combined monitoring stream data from multiple sources. #####


integrate_data <- function(SBUserName, SBPassword){
  
  library(dplyr)
  library(readxl)
  library(tidyverse)
  library(openxlsx)
  library(sf)
  library(tmap)
  library(httr)
  library(data.table)
  library(sp)
  library(sbtools)
  library(rgdal)
  library(ggplot2)
  library(sjmisc)
  
  ##### Sign into ScienceBase and pull data set information #####
 # SBUserName  <- readline(prompt="ScienceBase User Name: ")
  #SBPassword  <- readline(prompt="ScienceBase Password: ")
  

  authenticate_sb(SBUserName, SBPassword)


# Data Exchange Specifications are documented in this repository: https://github.com/rascully/Stream-Monitoring-Data-Exchange-Specifications

#List of programs to integrated data from. Can add PIBO when they release their data    
program <-c("NRSA","AREMP", "AIM", "PIBO")
orginization <- c("EPA", "USFS", "BLM", "USFS")

#ScienceBase ID of the parent item for integrating stream habitat metrics 
sb_id <-"5e3c5883e4b0edb47be0ef1c"
  
#Get the list of programs from the parent ScienceBase Item 
sb_child <- item_list_children(sb_id)
  
######Create the Record Level Data Table #####
  #Based on the data exchange specifications we need to create a record level table to document the metadata
  #about the each data sets. Download the 
  
#Git Hub link to the Record Level/Dataset table template 
github_link <- "https://raw.githubusercontent.com/rascully/Stream-Monitoring-Data-Exchange-Specifications/master/Tables/ODMDatasets_table.csv" 
temp_file <- tempfile(fileext = ".csv")
req <- GET(github_link, 
           # authenticate using GITHUB_PAT
             authenticate(Sys.getenv("GITHUB_PAT"), ""),
             # write result to disk
             write_disk(path = temp_file))
Record_level<- read.csv(temp_file)
unlink(temp_file)
  
#create an empty dataframe to fill with the record level data exchange specifications 
record_level_table     <- data.frame(matrix(ncol=length(Record_level$Term), nrow=length(program))) #replace program with sbchild if we want to use sb as a tool
record_level_table     <-  record_level_table %>% 
                             mutate_all(as.character)
  
#name the columns in the dataframe with the Record Level terms
colnames(record_level_table)  <- Record_level$Term 
# Fill in the Reach Level table with information about each data set 
 
  for(i in 1:length(sb_child)){ 
     record_level_table$DatasetTitle[i]    <- sb_child[[i]][["title"]]
     record_level_table$datasetID[i]      <- sb_child[[i]][["id"]]
     
     p_index <- str_contains( sb_child[[i]][["title"]], program) 
     record_level_table$DatasetOrginizationCode[i] <- paste (orginization[p_index], program[p_index]) 
     program[p_index]
  }

  record_level_table$Modified    <-   Sys.Date()
  record_level_table$DatasetType        <- "Water Quality and Physical Habitat Structure"

  ##### Open Git File Of Crosswalk #####
    
   # metadata  <- as_tibble(read_xlsx(paste0(wd,"/Metadata.xlsx") , 3))
    github_link <-"https://raw.githubusercontent.com/rascully/Stream-Monitoring-Data-Exchange-Specifications/master/Tables/Crosswalk.csv"
    temp_file <- tempfile(fileext = ".csv")
    
    # get the git file and save the temp 
    req <- GET(github_link, 
               # authenticate using GITHUB_PAT
               authenticate(Sys.getenv("GITHUB_PAT"), ""),
               # write result to disk
               write_disk(path = temp_file))
    
    cross_walk      <- read.csv(file= temp_file)
    cross_walk      <- cross_walk %>% 
                        mutate_all(na_if, "")
    CW              <- cross_walk %>% 
                        dplyr::select(c(Table,LongName, Term, DataType ,AREMPField, AIMField, NRSAField, PIBOField)) 
                        
    subset_metrics  <- as_tibble(lapply(CW, as.character))
    subset_methods  <- dplyr::select(cross_walk, contains("Term")| contains("MethodID")| contains("Unit") |"measurementType"|"measurementID")
    
    
    #array of the field names used in the combined data set  
    short_names <- CW$Term
    #array of a list of the data types of each variable 
    data_types  <- CW$DataType
   
    #list of unique data types 
    unique_data_types <- unique(data_types)
    
    #Create a empty dataframe with the field names  
    all_data <- data.frame(matrix(ncol = length(short_names), nrow = 1))
    colnames(all_data) <- short_names
    
##### For loop to add data from each program to one data set #####
  for(p in program) {
        #Load the data 
           if (p=="NRSA"){
             print("NRSA")
             #Download the data from ScienceBase 
             file_name<- paste0(getwd(),"/data/", "Tidy_NRSA_Data_Set.csv")
             data <-as_tibble(read.csv(file_name))
                   
              #Fill in Reach Level table 
              
                } else if (p=="AIM") { 
                  print("AIM")
                    #create a URL to access the BLM Data
                    url <- list(hostname = "gis.blm.gov/arcgis/rest/services",
                                scheme = "https",
                                path = "hydrography/BLM_Natl_AIM_AquADat/MapServer/0/query",
                                query = list(
                                  where = "1=1",
                                  outFields = "*",
                                  returnGeometry = "true",
                                  f = "geojson")) %>% 
                                  setattr("class", "url")
                      
                    request <- build_url(url)
                    BLM <- st_read(request, stringsAsFactors = TRUE) #Load the file from the Data file 
                    data <- as_tibble(BLM)
                    file_path <- paste0(getwd(), "/Data/Tidy_BLM.csv")
                    file.remove(file_path)
                    write.csv(data, file=file_path, row.names=FALSE)
                    
                  #Fix the date 
                    data$DT <- as.POSIXct(data$DT/1000, origin="1970-01-01")
                    data$DT <- str_remove(data$DT, " 17:00:00 PDT")
                    data$DT <- as.Date.character(str_remove(data$DT, "17:00:00"))
                
                  #Fill in Record Level table with the cititation 
                    
                  
                  } else if (p=="PIBO"){ 
                    print("PIBO")  
                    data <- as_tibble(read_xlsx("Data/2020_Seasonal_Sum_PIBO.xlsx", 2))
                   #Fill in record_level table 
                      index <- str_detect(record_level_table$datasetName, "PIBO")
                      record_level_table$DatasetOrginizationCode[index]<- "USFS"
                      #record_level_table$CollectionID[index]<- "PIBO"
                      datasetID <- record_level_table$datasetID[index]
                 
                  } else if (p== "AREMP") {
                    print("AREMP")
                  #Download the data table from the ScienceBase item
                    file_name<- paste0(getwd(),"/data/", "Tity_AREMP_Data_Set.csv")
                    data <-as_tibble(read.csv(file_name))
                  
                  #Fill in Record Level table 
                    index <- str_detect(record_level_table$DatasetTitle, "AREMP")
                    record_level_table$Citation[index]   <- 	"Miller, Stephanie A.; Gordon, Sean N.; Eldred, Peter; Beloin, Ronald M.; Wilcox, Steve; Raggon, Mark;
                                                                    Andersen, Heidi; Muldoon, Ariel. 2017. Northwest Forest Plan—the first 20 years (1994–2013): watershed 
                                                                    condition status and trends. Gen. Tech. Rep. PNW-GTR-932. Portland, OR: U.S. Department of Agriculture,
                                                                    Forest Service, Pacific Northwest Research Station. 74 p."
                    
              }
         
    #create a column name to reference 
          column <- paste0(p,"Field")
    #Data frame of the the names of the fields in the cross walk 
          program_metric_names <- subset_metrics %>% 
              dplyr::select(c(column,"Term", "DataType")) %>% 
              drop_na(column)

          
          #check the metrics in the cross_walk are in the data set and create a vector of the 
          #names for the final data set 
          
          specific_names<- as.vector(unlist(dplyr::select(program_metric_names, column)))
          
          CW_names_index        <- names(data) %in% specific_names
          CW_names              <- names(data)[CW_names_index]
          data_set_names_index  <- specific_names %in% CW_names 
          data_set_names        <- program_metric_names$Term[data_set_names_index]
        
          #array of cross walk names that at this time are not in the origin data sets 
          CW_names_not_found  <- names(data)[!CW_names_index]
          
          #Clear SubSetData variable 
          SubSetData <- 0
          #Subset the data from the master dataframe 
          SubSetData <- data %>%
            dplyr::select(CW_names)
          
          #Rename to the standard column names to the master data set names 
          for(n in 1:length(data_set_names)){
            if (n ==1)  {data_set_name <- character(length(data_set_names))
                        ordered_data_type <- character(length(data_set_name))}
            program_name          =  names(SubSetData)[n]
            name_index            <- specific_names == program_name
            data_set_name[n]      <- program_metric_names$Term[name_index]
            ordered_data_type[n]  <- program_metric_names$DataType[name_index]
          } 
         
          n = 0
          colnames(SubSetData)<- data_set_name
        
          #Assign a datatypes to each metric so it matches the data frame   
          SubSetData[ordered_data_type== "Numeric"]    <- sapply(SubSetData[ordered_data_type== "Numeric"], as.double)
          SubSetData[ordered_data_type== "String"]     <- sapply(SubSetData[ordered_data_type=="String"], as.character)
          SubSetData[ordered_data_type== "Date"]       <- sapply(SubSetData[ordered_data_type=="Date"], as.character)
          SubSetData[ordered_data_type== "Interger"]   <- sapply(SubSetData[ordered_data_type=="Interger"], as.character)
          
          #Add a column a program and Program 
          SubSetData$Program   <- p
          #Add the datasetID
          SubSetData$datasetID <- record_level_table$datasetID[str_detect(record_level_table$DatasetOrginizationCode, p)]
      #If the program AREMP or PIBO add WADEABLE, because all AREMP and PIBO sites are Wadable
          if (str_detect(p, "AREMP|PIBO")) {SubSetData$samplingProtocol <- "WADEABLE"} 
         
    #Add the program data to the full data set 
          all_data=bind_rows(all_data, SubSetData)
          
       #   if (any(str_detect("1004784", all_data$verbatimActionID))) {
        #  print(filter(all_data, str_detect("1004784", all_data$verbatimActionID)))
         # } 
    }
      
##### Clean up the data 
 # plot(all_data$verbatimLongitude, all_data$verbatimLatitude)
  all_data2 = all_data %>%
              filter(!is.na(verbatimLongitude) & !is.na(verbatimLatitude))
  
  blank_test = all_data %>%
    filter(is.na(verbatimLongitude) & is.na(verbatimLatitude))
  
  
  #Fill in location data with the verbatimLocation, 
  #as we add additional data sets we will need to think about creating a SpatialReferenceID
  #for the integrated data set. Just to make sure that programs don't repeat SpatialReferenceIDs 
  all_data2$SpatialReferenceID  <- all_data2$verbatimSpatialReferenceID
  
  #create a list of sites with unique locations 
  u_locations <- dplyr::select(all_data2, (c(SpatialReferenceID, verbatimLatitude, verbatimLongitude,
                                             samplingFeatureName, Program)))
  
  unique_locations <- distinct(u_locations)
  unique_path <- paste0(getwd(), "/data/unique_locations.csv")
  file.remove(unique_path)
  write.csv(unique_locations, file=unique_path, row.names=FALSE)
  
# Check if there are blanks in the year
  blank_year                  <- is.na(all_data2$Year)
  all_data2$year[blank_year]  <- substr(all_data2$EventDate[blank_year],1, 4) 
  all_data2$Year              <- as.integer(all_data2$Year)
 
# Check if there are blanks in the verbatimSamplingFeatureID, fill in SamplingFeatureID
  no_SamplingFeatureID <- is.na(all_data2$verbatimSamplingFeatureID)
  all_data2[no_SamplingFeatureID,]
  all_data2$SamplingFeatureID[no_SamplingFeatureID] <-  paste0(all_data2$verbatimActionID[no_SamplingFeatureID],
                                                               all_data2$BeginDataTime[no_SamplingFeatureID], all_data2$Program[no_SamplingFeatureID])
  all_data2$SamplingFeatureID[!no_SamplingFeatureID ] <- all_data2$verbatimActionID[!no_SamplingFeatureID ]


#Check if there are blanks in the verbatimActionID
    all_data2$verbatimActionID[is.na(all_data2$verbatimActionID)]

#Check for blank verbatimActionID, where it is blank fill in the ActionID with the locaitonID concatenated with the Program name 
  no_ActionID <- is.na(all_data2$verbatimActionID)
  all_data2$ActionID[no_ActionID] <-  paste0(all_data2$verbatimSpatialFeatureID[no_ActionID], all_data2$BeginDataTime[no_ActionID], all_data2$Program[no_ActionID])
  all_data2$ActionID[!no_ActionID] <- all_data2$verbatimActionID[!no_ActionID]
 
 #####Check for duplicates in the ActionIDs 
  dupl_ActionID <- all_data2 %>% 
    filter(duplicated(ActionID)) 
  
  # Fill in duplicates with verbatim ActionID contacinated with program name 
  index <- str_detect(all_data2$ActionID, paste(c(dupl_ActionID$ActionID), collapse = "|"))
  dupl_ActionID =  all_data2[index,]
  all_data2$ActionID[index] = paste0(all_data2$ActionID[index], "-", all_data2$Program[index])
 
  
####Subset the data set to match the data exchange specifications documented on https://github.com/rascully/Stream-Monitoring-Data-Exchange-Specifications#####
### Subset the sampling features/locations 
  github_link <- "https://raw.githubusercontent.com/rascully/Stream-Monitoring-Data-Exchange-Specifications/master/Tables/ODMSamplingFeature_table.csv" 
  temp_file <- tempfile(fileext = ".csv")
  req <- GET(github_link, 
             # authenticate using GITHUB_PAT
             authenticate(Sys.getenv("GITHUB_PAT"), ""),
             # write result to disk
             write_disk(path = temp_file))
  
  Location_table<- read.csv(temp_file)
  location_table <- all_data2 %>% 
                    dplyr::select(one_of(c("datasetID", "Program", Location_table$Term))) %>% 
                    distinct()
   
  
#Build the event table/action table 
  github_link <- "https://raw.githubusercontent.com/rascully/Stream-Monitoring-Data-Exchange-Specifications/master/Tables/ODMAction_table.csv" 
  temp_file <- tempfile(fileext = ".csv")
  req <- GET(github_link, 
             # authenticate using GITHUB_PAT
             authenticate(Sys.getenv("GITHUB_PAT"), ""),
             # write result to disk
             write_disk(path = temp_file))
  Event_table <- read.csv(temp_file)    
  event_table <- all_data2 %>% 
                  dplyr::select(one_of(c("Program","SpatialReferenceID", Event_table$Term)))


#Create the measurement of fact table 
  measurement_names <- CW %>% 
      filter(str_detect(CW$Table, "ControlledVocabulary"))  %>% 
      dplyr::select(Term) %>% 
      pull()
  
 measurement <- all_data2 %>% 
   dplyr::select(Program, ActionID, measurement_names) %>% 
   add_column(methodID= "", measurementRemarks='', ResultTypeCV='') %>% 
   dplyr::rename(measurementDeterminedBy = Program)

 Results <- measurement %>% 
   pivot_longer(cols = measurement_names, 
                names_to ="measurementTerm", values_to="DataValue") %>% 
   drop_na(DataValue) %>% 
   add_column(VariableID="") %>% 
   rowid_to_column("ResultID")  
                        
 
 #Add the measurmentID to the measurement or fact table 

 for(term in unique(Results$measurementTerm)){ 
  method_info <- subset_methods %>% 
     filter(Term == term)
   
   m_index                            <- Results$measurementTerm==term
   Results$VariableID[m_index]      <- dplyr::select(method_info, "measurementID")
   Results$ResultTypeCV[m_index]      <- dplyr::select(method_info, "measurementType")
   
   #Results$measurementUnit[m_index]  <- dplyr::select(method_info, measurementUnit)
   #add the measurement type 
    #Results$measurementType[m_index]  <- dplyr::select(method_info, "measurementType")
     
   for(p in program){
   # Add the link to the MonitoringResources.org 
     metric_field <- paste0(p, "CollectionMethodID")  
     
     mr_method <- method_info %>% 
         dplyr::select(contains(metric_field)) 
    
     index    <- Results$measurementTerm==term & Results$measurementDeterminedBy==p
     Results$methodID[index] <- mr_method

     }
 } 

Results<- Results %>% 
              relocate(c("ActionID","ResultID", "ResultTypeCV", "VariableID","measurementTerm","DataValue", 
                         "measurementDeterminedBy","methodID", "measurementRemarks" ))  

#Write data to a .csv
    file_path <- paste0(getwd(), "/Data/Flat Integrated Data Set.csv")
    file.remove(file_path)
    write.csv(all_data2, file=file_path, row.names=FALSE)
       

  #Save the data set 
    list_of_datasets <- list("Datasets" = record_level_table, "SamplingFeature"= location_table, "Action"= event_table,
                             "Results"= Results, "VariableCV"= cross_walk)
    
    file_name = "data/Integrated Data Set.xlsx"
    file.remove(file_name)
    openxlsx::write.xlsx(list_of_datasets, file = file_name) 

  #Write the integrated data set to ScenceBase  
    #authenticate_sb(SBUserName, SBPassword)
    sb_id = "5e3c5883e4b0edb47be0ef1c"
    item_replace_files(sb_id,file_name, title = "IntegratedDataSet")  
    
#Update ScienceBase Item   
    item_replace_files(sb_id,unique_path, title ="A list of unique data collection locations")  
    

# Update the last Processed date to indicate the last time the code was run 
    sb_dates <- item_get_fields(sb_id, c('dates'))
    
    for(d in 1:length(sb_dates)){ 
      if(sb_dates[[d]][["type"]]=='lastProcessed') {
        sb_dates[[d]][["dateString"]] <- Sys.Date() 
        items_update(sb_id, info = list(dates = sb_dates)) 
      }
    }
    
    
return(list_of_datasets) 

}

