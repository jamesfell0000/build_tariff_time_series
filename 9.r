#9. Now we have a list of bilateral product level tariffs. We then need to summarise that list so that it gives us the lowest preferential tariff (use aggregate and min)
minimum_pref_tariffs <- aggregate(list(min_tariff=pref_tariffs$obsValue), list(obsTime=pref_tariffs$obsTime,PRODUCTCODE=pref_tariffs$PRODUCTCODE,REPORTER=pref_tariffs$REPORTER,PARTNER=pref_tariffs$PARTNER),min)
