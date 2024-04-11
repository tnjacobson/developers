*Explore Dispo
global data "${dropbox}/development/data/raw"
global export "${dropbox}/development/figures/nyc_charter"


*-------------------------------------------------------------------------------
*Time Series of Land Use Applications
*-------------------------------------------------------------------------------
import delim "${data}/nyc_housing/nyc_zap/zapprojectbbls_20240101csv/zap_projectbbls", clear bindquote(strict)

keep project_id bbl 
tempfile bbls 
save `bbls'


*Load in Data
import delim "${data}/nyc_housing/nyc_zap/zapprojects_20240101csv/zap_projects", clear bindquote(strict)

merge 1:m project_id using `bbls'

*Cleaning Up Dates:
foreach var in app_filed_date approval_date completed_date certified_referred {
	gen has_`var' = !mi(`var')
	
}



gen date = date(certified_referred, "YMD")
gen year = year(date)
gen count = 1 

keep if project_status == "Complete"
gen approve = project_status == "Complete"
replace project_brief = strlower(project_brief)

gen dispo = 0 
replace dispo = 1 if strpos(project_brief, "dispo") != 0
gen acq = 0 
replace acq = 1 if strpos(project_brief, "acq") != 0


sort year 

keep if dispo == 1 


br project_brief bbl year 
*Some numbers to lookup 
*P1977X0337

