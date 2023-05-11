#4. Replace the RTA partner codes with the RTA_grouping_code (this is necessary for imputation because different RTA partner codes are used for the same RTA).
#Read in the RTA groupings from the csv
RTA_groupings <- read.csv(RTA_groupings_CSV) #File available in this repository
RTA_groupings <- subset(RTA_groupings, select=c("PARTNER", "RTA_group","Impute_until"))

#Merge in the imputation group to the tariffs df
tariffs <- merge(tariffs,RTA_groupings,by="PARTNER",all.x=TRUE)
tariffs$PARTNER[!(is.na(tariffs$RTA_group))] <- tariffs$RTA_group[!(is.na(tariffs$RTA_group))]
