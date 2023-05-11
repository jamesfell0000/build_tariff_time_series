#2. Download all the data
#This requires looping through each reporter and each year.
#First need Reporter list:
#Download all the country codes from WITS
#countries <- read_xml("http://wits.worldbank.org/API/V1/wits/datasource/tradestats-tariff/country/ALL")
countries <- read_xml("http://wits.worldbank.org/API/V1/wits/datasource/trn/country/ALL")
country_details <- xml_find_all(countries, ".//wits:country")
#Get country code list
country_code_list <- as.data.frame(xml_attr(country_details, "countrycode"))
#Get details about whether a country is classified as a reporter
country_code_list_isreporter <- as.data.frame(xml_attr(country_details, "isreporter"))
#Combine the previous two lists
reporter_df <- cbind(country_code_list,country_code_list_isreporter)
#Change the column names to something logical
colnames(reporter_df)[1:2] <- c("countrycode", "isreporter")
#Filter to just reporters
reporter_df <- reporter_df[reporter_df$isreporter=="1",]
#Get the list of reporters from the dataframe
reporter_list <- as.list(reporter_df$countrycode)

#Create a dataframe to store our data:
tariffs <- data.frame()

Sys.time()
#The wits API can't cope with large downloads, so we need to advance one year at a time, one reporter at a time, one product at a time by looping through the years and countries.
products <- paste(product_list, collapse = "+")

for (reporter in reporter_list) {
	for (year in years_list) {
	  #First build the url
	  url <- paste0("http://wits.worldbank.org/API/V1/SDMX/V21/rest/data/DF_WITS_Tariff_TRAINS/A.",reporter,"..",products,".aveestimated/?startperiod=",year,"&endperiod=",year,"&detail=Full")
	  #Check there are data available before downloading:
	  data_availability_check <- GET(url)
	  if (status_code(data_availability_check) == 200) {
	    #Download the data
	    dataset <- readSDMX(url)
 	   #Convert the data to a dataframe
 	   year_df <- as.data.frame(dataset)
	    #Bind this year's data to the previous year's data.
	    tariffs <- rbind(tariffs,year_df)
	  }
	}
}
Sys.time()
