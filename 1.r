#1. What codes do you want?
product_list <- list("940370") #Can do as a list e.g. list("100199","100190")
#What years do you want?
years_list <- as.list(1988:2020)

#Insert codes that are considered to be the same product, e.g. wheat used to be 100190, and is now effectively 100199.
common_commodity_code <- function() {
	#No concordance needed for plastic furniture (HS codes haven't changed, but wheat example is given below)
	#tariffs_df$PRODUCTCODE[tariffs_df$PRODUCTCODE == "100190"] <- "100199"
}
