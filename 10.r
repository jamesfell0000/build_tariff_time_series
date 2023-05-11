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
