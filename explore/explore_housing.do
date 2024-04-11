*Explore Housing Data 

global data "${dropbox}/development/data/derived/housing"

import delim "${data}/housing_construction", clear

keep if inrange(year_built, 2010, 2020)

gen pd = substr(zone_class2023,1,2) == "PD"

gen has_zoning_change = 
