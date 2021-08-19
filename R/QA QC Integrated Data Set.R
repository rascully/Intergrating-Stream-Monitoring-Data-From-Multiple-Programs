#####QA of integrated data set 

library(xlsx)
library(openxlsx)
library(httr)
library(tidyverse)
library(data.table)

#Packages to format table
library(knitr)
library(kableExtra)

# packages for downloading and formatting shapefiles & other GIS Data 
library(downloader)
library(rgdal)
library(RCurl)
library(sf)

#Mapping, graphing and visualizations packages 
library(shiny)
library(leaflet)
library(dplyr)
library(leaflet.extras)
library(DT)
library(ggplot2)



data <- read.csv(paste0(getwd(), "/data/Flat Integrated Data Set.csv")) 

path<-paste0(getwd(), "/data/Integrated Data Set.xlsx")
sheets <- openxlsx::getSheetNames(path)
data_set <- read.xlsx(paste0(getwd(), "/data/Integrated Data Set.xlsx"))
data <- lapply(sheets, openxlsx::read.xlsx, xlsxFile=path)
names(data) <- sheets

for (n in names(data)) { 
  assign(n, data[[n]])
  }

boat <- Events %>% 
      filter(invert_match(str_detect(samplingProtocol,("WADEABLE"))))

wade_ID <- Events %>% 
        filter(str_detect(samplingProtocol,("WADEABLE"))) 
        
  #select("eventID") %>% 
   #     pull( eventID)

str_subset(measurments$eventID, wade_ID)

measurments_wide<- Measurment_or_Fact %>% 
                    select(eventID, measurementValue, measurementTerm) %>% 
                    pivot_wider(names_from = measurementTerm, values_from = measurementValue)


wide_measurements <- Measurment_or_Fact %>% 
                pivot_wider(names_from = measurementTerm, values_from= c(measurementValue, measurementType, measurementID, measurementUnit))
  
  
  
unique(measurements$measurementTerm)

measurements_wade <- measurements[str_detect(measurements$eventID, wade_ID),]

metrics <-  unique(measurements$measurementTerm)

for (m in metrics) {
   
   to_plot <- measurements %>% 
        filter(measurements$eventID %in%  wade_ID$eventID ) %>% 
        filter(str_detect(measurementTerm, paste(c(m, "BFWidth"),collapse="|")))
      
                          
               
               
     to_plot$measurementDeterminedBy <- as.factor(to_plot$measurementDeterminedBy)
   
     box <- ggplot(to_plot, 
                  aes(x=measurementDeterminedBy, y= measurementValue, color= measurementDeterminedBy))+
                  geom_boxplot()+
                  ggtitle(m) 
     
      scatter <- ggplot(to_plot, 
                        aes(x=measurementDeterminedBy, y= measurementValue, color= measurementDeterminedBy))+
                        geom_point()+
                        ggtitle(m) 
      
      histogram <- ggplot(to_plot, 
                          aes(measurementValue, color= measurementDeterminedBy))+
                          geom_histogram()+
                          ggtitle(m) +  facet_wrap(~measurementDeterminedBy)
        
  # Open a pdf file
     filename <- paste0(getwd(), "/plots/", m, "_Boxplot.jpg")
     jpeg(filename)
     par(mfrow=c(3,1))
     print(box)
     print(scatter)
     print(histogram)
   # Close the file
     dev.off() 
  } 
 

p <- ggplot(measurements, 
            aes(x=measurementValue, y= measuremetTerm, color= measurementDeterminedBy))+
              geom_boxplot()+
              facet_grid(~measurmentTerm)
p 


p <- ggplot(measurements, 
            aes(x=measuremetTerm, y=measurementValue , color= measurementDeterminedBy))+
  geom_boxplot()+
  facet_grid(.~measurmentTerm)
p 







metric <- data %>% 
          select("Grad", "Program") 
#ggplot(nvcs_h, aes(nvcs_h[1]))+geom_histogram()+facet_wrap(~Program)
#ggplot(nvcs_h, aes(input$metric))+ geom_point()+facet_wrap(~Program)
qplot(nvcs_h[,1], geom='histogram')+ xlab(names(nvcs_h[1]))

qplot(nvcs_h[,1], geom='histogram')+ xlab(names(nvcs_h[1]))

ggplot(nvcs_h, aes(nvcs_h[1]))+geom_histogram()+facet_wrap(~Program)