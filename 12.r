#12. Calculate the minimum tariff for each partner/reporter/year.
min_bilateral_tariffs <- aggregate(list(min_tariff=MFNs_and_pref_tariffs$min_tariff), list(year=MFNs_and_pref_tariffs$obsTime,PRODUCTCODE=MFNs_and_pref_tariffs$PRODUCTCODE,REPORTER=MFNs_and_pref_tariffs$REPORTER,PARTNER=MFNs_and_pref_tariffs$PARTNER),min)
