
RL_Table <- function(datasetID,program){
#library(tidyverse)
#library(httr)
#library(xlsx)

#Pull the record level data exchange specifications from table from the GIT Repository https://github.com/rascully/Stream-Monitoring-Data-Exchange-Specifications
github_link <- "https://github.com/rascully/Stream-Monitoring-Data-Exchange-Specifications/blob/master/Tables/RecordLevel.xlsx?raw=true"
temp_file <- tempfile(fileext = ".xlsx")
req <- GET(github_link, 
           # authenticate using GITHUB_PAT
           authenticate(Sys.getenv("GITHUB_PAT"), ""),
           # write result to disk
           write_disk(path = temp_file))

RL <- readxl::read_excel(temp_file) #read in the record level data exchange specifications 
unlink(temp_file)
  
RL_table            <- data.frame(matrix(ncol=length(RL$TERM), nrow=0)) #create an empty dataframe to fill with the record level data exchange specifications 
colnames(RL_table)  <- RL$TERM #name the columns in the dataframe with the Record Level terms 


      RL_table$datasetID                =   datasetID
     # RL_table$type                     = 
      RL_table$modified                 =   Sys.Date()
      RL_table$rightsHolder             =   program
      #RL_table$bibilographicCititation  =   
      #RL_table$InstitutionID            =   
      #RL_table$CollectionID             = 
      #RL_table$datasetName              = 
      #RL_table$institutionCode          = 
      #RL_table$basisOfRecord            = 
      #RL_table$informationWithheld      =
}


