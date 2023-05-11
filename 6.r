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
