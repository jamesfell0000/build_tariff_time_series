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
