#7. Extract out the MFNs and put them in a different dataset. Create a dataset with no MFNs, call it the preferential dataset.
MFNs <- tariffs_df[tariffs_df$PARTNER=="000",]
saveRDS(MFNs,'MFNs.rds')
pref_tariffs <- tariffs_df[!(tariffs_df$PARTNER=="000"),]
saveRDS(pref_tariffs,'pref_tariffs.rds')
