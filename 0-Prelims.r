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
#Download the following csv file from https://github.com/jamesfell0000/build_tariff_time_series/blob/main/pref_imput_groups.csv
RTA_groupings_CSV <- 'pref_imput_groups.csv' #This is a custom file created by me, interpreting inconsistent RTA descriptions and grouping them as consistent RTAs. The basis for this is the file at http://wits.worldbank.org/data/public/TRAINSPreferenceBenficiaries.xls
#Download the following csv file from https://github.com/jamesfell0000/build_tariff_time_series/blob/main/RTA_members.csv
RTA_members_CSV <- 'RTA_members.csv' #Create this file yourself from http://wits.worldbank.org/data/public/TRAINSPreferenceBenficiaries.xls
