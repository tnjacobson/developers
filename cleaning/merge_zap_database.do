*Merging Lobbyists with Zoning Application

global data "${dropbox}/development/data/raw/nyc_housing"

*Loading in Lobbying Data
import delim "${data}/lobbying/City_Clerk_eLobbyist_Data_20240201.csv", clear
keep if client_industry == "Real Estate, Construction, Engineering & Developer"
rename client_name entity 


replace entity = strlower(entity)
collapse (rawsum) compensation_total, by(entity)

tempfile lobbying
save `lobbying'




keep if ulurp_non == "ULURP"

gen date = date(certified_referred, "YYYYMMDD")

gen entity = strlower(primary_applicant)

merge m:1 entity using `lobbying', keep(1 3)

gen match = _merge == 3 

tab year, sum(match)

gen llc = strpos(entity, "llc") != 0 

*-------------------------------------------------------------------------------
*Start with List of Projects
*-------------------------------------------------------------------------------
*Load in BBLS
import delim "${data}/nyc_zap/zapprojectbbls_20240101csv/zap_projectbbls", clear bindquote(strict)
drop if mi(bbl)
keep bbl project_id
tempfile bbls
save `bbls'


import delim "${data}/Housing_Database_Project_Level_Files_20240129", clear bindquote(strict)

keep if job_type == "New Building"
keep if classanet != 0



merge 


import delim "${data}/nyc_zap/zapprojects_20240101csv/zap_projects", clear bindquote(strict)



tempfile zoning 
save `zoning'
