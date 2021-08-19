# Integrating Stream Habitat Metrics 
This repository contains the code to integrate stream habitat metrics from three stream habitat monitoring programs EPA National Aquatic Resources Surveys (NARS), BLM Aquatic Assessment, Inventory, and Monitoring, and USFS Aquatic and Riparian Effective Monitoring Program (AREMP). We integrate data based on the data exchange specifications in the [Stream Monitoring Data Exchange Specifications repository](https://github.com/rascully/Stream-Monitoring-Data-Exchange-Specifications). 

# Purpose
Improving data sharing will enable timely access to data, enhance data quality, and create clear channels for better management decisions. Healthy aquatic habitat is critical to fishes, aquatic species, and water quality. Across the US, long-term, large-scale stream habitat monitoring programs collect data for their specific objectives and within their jurisdictional boundaries. Streams cross jurisdictional boundaries and face unprecedented pressure from changing climate, multi-use public lands, and development. To meet these stresses, we integrate data from multiple sources to create a data set of stream metrics across jurisdictional boundaries. We focus on integrating data from the EPA National Aquatic Resources Surveys (NARS), BLM Aquatic Assessment, Inventory and Monitoring, and USFS Aquatic and Riparian Effective Monitoring Program (AREMP). This code integrates a subset of metrics collected on public lands in the Western United States and documents metadata in MonitoringResources.org based on the data exchange specifications and crosswalks outlined in the [Stream Monitoring Data Exchange Specifications repository](https://github.com/rascully/Stream-Monitoring-Data-Exchange-Specifications). 

# Preprossing  
Before we could build the integrated data set we pre-processed two of the input data sets 

### Pre-processing 
We pre-process the AREMP and EPA NRSA data sets to flatten them and save the outputs in the data file. 
<ul>
<li>[Code to Download and Tidy AREMP Data](https://github.com/rascully/Integrating-Stream-Monitoring-Data-From-Multiple-Programs/blob/master/R/Pull%20AREMP%20Data.R) and [Tity AREMP Data Set](https://github.com/rascully/Integrating-Stream-Monitoring-Data-From-Multiple-Programs/blob/master/Data/Tity_AREMP_Data_Set.csv) </li>
<li> [Code to Scrape and Tidy NRSA Data](https://github.com/rascully/Integrating-Stream-Monitoring-Data-From-Multiple-Programs/blob/master/R/Scrape%20EPA%20data.R) and [Tity NRSA Data Set](https://github.com/rascully/Integrating-Stream-Monitoring-Data-From-Multiple-Programs/blob/master/Data/Tidy_NRSA_Data_Set.csv)</li>
</ul>

# Inputs 
We built the integrated data set based on the [workflow](https://github.com/rascully/Stream-Monitoring-Data-Exchange-Specifications/blob/master/Figures/WorkFlow.png) documented in the data exchange specifications, with the following inputs:  
<ul>
<li> [Tidy AREMP Data Set](https://github.com/rascully/Integrating-Stream-Monitoring-Data-From-Multiple-Programs/blob/master/Data/Tity_AREMP_Data_Set.csv)</li>
<li> [Tidy NRSA Data Set](https://github.com/rascully/Integrating-Stream-Monitoring-Data-From-Multiple-Programs/blob/master/Data/Tidy_NRSA_Data_Set.csv) </li> 
<li> [BLM AIM GIS Server Data](https://landscape.blm.gov/geoportal/rest/find/document;jsessionid=4CFD5847911DC2584BD9B1F23E98C96C?searchText=isPartOf%3AAIM&contentType=liveData&start=1&max=10&f=searchpage) </li>
<li> [Data Exchange Specifications](https://github.com/rascully/Stream-Monitoring-Data-Exchange-Specifications) </li> 
<li> [Schema Cross walk](https://github.com/rascully/Integrating-Stream-Monitoring-Data-From-Multiple-Programs/blob/master/Data/Tity_AREMP_Data_Set.csv), cross walking original data sets fields to the controlled vocabulary </li>
<li>[MonitoringResources.org](MonitoringResources.org) Methods </li>
</ul>


# Outputs
We integrated a subset of metrics and metadata from the four programs the following data files are produced and saved in the data file of this repository and uploaded to [ScienceBase](https://www.sciencebase.gov/catalog/). 
<ul>
<li>[Unique Locations](https://github.com/rascully/Integrating-Stream-Monitoring-Data-From-Multiple-Programs/blob/master/Data/unique_locations.csv)- a list of the unique location of data collection from the three programs included in the integrated data sets</li>
<li>[Integrated Data Set](https://github.com/rascully/Integrating-Stream-Monitoring-Data-From-Multiple-Programs/blob/master/Data/Integrated%20Data%20Set.xlsx)- data set constructed using the data [Stream Monitoring Data Exchange Specifications](https://github.com/rascully/Stream-Monitoring-Data-Exchange-Specifications)</li>
<li>[Flat Integrated Data Set](https://github.com/rascully/Integrating-Stream-Monitoring-Data-From-Multiple-Programs/blob/master/Data/Flat%20Integrated%20Data%20Set.xlsx)- a flat file of the integrated data sets.  </li>
</ul> 






