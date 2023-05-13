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
pref_tariffs$PARTNER[is.na(pref_tariffs$PARTNER)] <- pref_tariffs$PARTNER_original #You might get a warning.
saveRDS(pref_tariffs,'pref_tariffs.rds')
