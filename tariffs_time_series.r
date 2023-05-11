#Code to get historical tariff dataset on a bilateral product level.

#Install and load packages
#install.packages(c("rsdmx","httr","xml2","utils","tidyr","dplyr")) #uncomment if you need to install them
library(rsdmx)
library(httr)
library(xml2)
library(utils)
library(tidyr)
library(dplyr)

#Insert file names
RTA_groupings_CSV <- 'pref_imput_groups.csv' #This is a custom file created by me, interpreting inconsistent RTA descriptions and grouping them as consistent RTAs. The basis for this is the file at http://wits.worldbank.org/data/public/TRAINSPreferenceBenficiaries.xls
RTA_members_CSV <- 'RTA_members.csv' #Create this file yourself from http://wits.worldbank.org/data/public/TRAINSPreferenceBenficiaries.xls

#Insert codes that are considered to be the same product, e.g. wheat used to be 100190, and is now effectively 100199.
common_commodity_code <- function() {
	tariffs_df$PRODUCTCODE[tariffs_df$PRODUCTCODE == "100190"] <- "100199"
}

#1. What codes do you want?
product_list <- list("100199","100190")
#What years do you want?
years_list <- as.list(1988:2020)





#2. Download all the data
#This requires looping through each reporter and each year.
#First need Reporter list:
#Download all the country codes from WITS
countries <- read_xml("http://wits.worldbank.org/API/V1/wits/datasource/tradestats-tariff/country/ALL")
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
		year_df$EXCLUDEDFROM <- NULL #Get rid of this column, not hugely useful and doesn't always appear
	    #Bind this year's data to the previous year's data.
	    tariffs <- rbind(tariffs,year_df)
	  }
	}
}
Sys.time()


#3. Duplicate the column with the partners, call it 'partner_original'. This is so we can populate the RTAs later, but in the meantime we need to replace the partners with an RTA grouping code for imputation purposes.
tariffs$PARTNER_original <- tariffs$PARTNER


#4. Replace the RTA partner codes with the RTA_grouping_code (this is necessary for imputation because different RTA partner codes are used for the same RTA).
#Read in the RTA groupings from the csv
RTA_groupings <- read.csv(RTA_groupings_CSV)
RTA_groupings <- subset(RTA_groupings, select=c("PARTNER", "RTA_group","Impute_until"))

#Merge in the imputation group to the tariffs df
tariffs <- merge(tariffs,RTA_groupings,by="PARTNER",all.x=TRUE)
tariffs$PARTNER[!(is.na(tariffs$RTA_group))] <- tariffs$RTA_group[!(is.na(tariffs$RTA_group))]


#5. Impute missing data
#build a dataframe with each reporter product partner year
#merge in tariffs by reporter product partner year
#fill gaps with tidyr, choose down
#remove row if tariff is na
partner_list <- as.list(unique(tariffs$PARTNER)) #this gets the list of partners who actually appear in the dataset (serves the purpose of imputation)
#Get list of partners. We do this now to save on
all_combinations_df <- expand.grid(REPORTER = reporter_list, PARTNER = partner_list,obsTime = years_list, PRODUCTCODE = product_list)
all_combinations_df <- as.data.frame(lapply(all_combinations_df, unlist))

#Merge all_combinations_df with tariffs
all_combinations_df <- merge(all_combinations_df, tariffs, by=c("REPORTER","PRODUCTCODE","PARTNER","obsTime"), sort=TRUE, all=TRUE)

#Add imputed tag if no tariff data, in preparation for imputing values
all_combinations_df$is_imputed <- "no"
all_combinations_df$is_imputed[is.na(all_combinations_df$obsValue)] <- "imputed"

#Impute missing values
tariffs_df <- all_combinations_df %>%
  dplyr::group_by(REPORTER,PRODUCTCODE,PARTNER) %>%
  fill(obsValue,NOMENCODE,PARTNER_original, .direction = "down") %>%
  dplyr::ungroup()

#remove cases of no data (this is because not all partners were available for all reporters, or if there was no data for a reporter/partner combo for years early on)
tariffs_df <- tariffs_df[!(is.na(tariffs_df$obsValue)),]


#6. Remove incorrect imputations
#Overwrite the product codes so they are all of the same hs version, e.g. 100190 becomes 100199.
#(change this to a function which will be defined above)
common_commodity_code()
#Do a count on the number of observations for each year, productcode, reporter, partner. Merge in the count. If the count is >1 and imputed = yes, then delete the observation.
tariffs_df$HS_version_obs <- as.numeric(substr(tariffs_df$NOMENCODE,2,2))
latest_HS_versions <- aggregate(list(HS_version=tariffs_df$HS_version_obs), list(obsTime=tariffs_df$obsTime,PRODUCTCODE=tariffs_df$PRODUCTCODE,REPORTER=tariffs_df$REPORTER,PARTNER=tariffs_df$PARTNER),max)
#merge in the latest HS versions
tariffs_df <- merge(tariffs_df,latest_HS_versions,by=c('obsTime','PRODUCTCODE','REPORTER','PARTNER'),all.x=TRUE)
#Get rid of it if it is imputed and not using the latest HS version.
tariffs_df <- tariffs_df[!(tariffs_df$is_imputed == "imputed" & (tariffs_df$HS_version_obs < tariffs_df$HS_version)),]


#7. Extract out the MFNs and put them in a different dataset. Create a dataset with no MFNs, call it the preferential dataset.
MFNs <- tariffs_df[tariffs_df$PARTNER=="000",]
saveRDS(MFNs,'MFNs.rds')
pref_tariffs <- tariffs_df[!(tariffs_df$PARTNER=="000"),]
saveRDS(pref_tariffs,'pref_tariffs.rds')


#8. expand out the RTA codes in the preferential dataset using the excel file of members of each RTA, using the partner_original column (I think you can just do a merge.y=ALL)
RTA_members <- read.csv(RTA_members_CSV)
RTA_members <- subset(RTA_members, select=c("PARTNER", "Country"))
RTA_members$PARTNER_original <- RTA_members$PARTNER
RTA_members$PARTNER <- NULL
pref_tariffs <- merge(pref_tariffs, RTA_members, by=('PARTNER_original'), all.x=TRUE)
#Change column names: PARTNER to PARTNER_AND_RTA, country to PARTNER
colnames(pref_tariffs)[which(names(pref_tariffs) == "PARTNER")] <- "PARTNER_AND_REGION"
colnames(pref_tariffs)[which(names(pref_tariffs) == "Country")] <- "PARTNER"
#If PARTNER is na then adopt the PARTNER_ORIGINAL code. (It can be NA because it could be a straight PTA, not RTA)
pref_tariffs[is.na(pref_tariffs$PARTNER)]$PARTNER <- pref_tariffs$PARTNER_original
saveRDS(pref_tariffs,'pref_tariffs.rds')


#9. Now we have a list of bilateral product level tariffs. We then need to summarise that list so that it gives us the lowest preferential tariff (use aggregate and min)
minimum_pref_tariffs <- aggregate(list(min_tariff=pref_tariffs$obsValue), list(obsTime=pref_tariffs$obsTime,PRODUCTCODE=pref_tariffs$PRODUCTCODE,REPORTER=pref_tariffs$REPORTER,PARTNER=pref_tariffs$PARTNER),min)


#10. Now we switch focus to the MFNs. This could be altogether in the steps above, but it is interesting to be able to show the difference between MFN and lowest preferential rate.
#Expand out the MFNs to all countries (could get a list of all the countries in the dataset, or do some otherway). (I think you can just do a merge.y=ALL)
#Get details about whether a country is classified as a partner
country_code_list_ispartner <- as.data.frame(xml_attr(country_details, "ispartner"))
country_code_list_isgroup <- as.data.frame(xml_attr(country_details, "isgroup"))
#Combine the previous three lists
partner_df <- cbind(country_code_list,country_code_list_ispartner,country_code_list_isgroup)
#Change the column names to something logical
colnames(partner_df)[1:3] <- c("countrycode", "ispartner","isgroup")
#Filter to just partners and no RTAs
partner_df <- partner_df[partner_df$ispartner=="1" & partner_df$isgroup=="No",]
partner_df$isgroup <- NULL
partner_df$ispartner <- NULL
partner_df$PARTNER <- "000"

#Do the merge:
MFNs <- merge(MFNs, partner_df, by=('PARTNER'), all.x=TRUE)
MFNs$PARTNER <- NULL
MFNs$PARTNER <- MFNs$countrycode
MFNs$countrycode <- NULL
MFNs <- subset(MFNs, select=c("obsTime", "PRODUCTCODE","REPORTER","PARTNER","obsValue"))
saveRDS(MFNs,'MFNs.rds')
colnames(MFNs)[which(names(MFNs) == "obsValue")] <- "min_tariff"

#11. Bind together the MFNs to the preferential dataset (merge on year, reporter, partner)
MFNs_and_pref_tariffs <- rbind(MFNs,minimum_pref_tariffs)

#12. Calculate the minimum tariff for each partner/reporter/year.
min_bilateral_tariffs <- aggregate(list(min_tariff=MFNs_and_pref_tariffs$min_tariff), list(year=MFNs_and_pref_tariffs$obsTime,PRODUCTCODE=MFNs_and_pref_tariffs$PRODUCTCODE,REPORTER=MFNs_and_pref_tariffs$REPORTER,PARTNER=MFNs_and_pref_tariffs$PARTNER),min)

