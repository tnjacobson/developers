*Merging Lobbying Records with Business Names
global data "${dropbox}/development/data/raw/nyc_housing"

*Load in Corp Data
import delim "${data}/Active_Corporations___Beginning_1800_20240202.csv", clear
replace entity = strlower(entity)
bys currententityname: keep if _n == 1

rename currententityname entity
keep entity dos* initaldosfilingdate


tempfile corp 
save `corp'

*Loading in Lobbying Data
import delim "${data}/lobbying/City_Clerk_eLobbyist_Data_20240201.csv", clear
keep if client_industry == "Real Estate, Construction, Engineering & Developer"
rename client_name entity 
replace entity = strlower(entity)
collapse (rawsum) compensation_total, by(entity)

merge 1:1 entity using `corp', keep(1 3)
