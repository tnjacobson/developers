*CLEAN ULURP


global data "${dropbox}/development/data/raw/nyc_housing"
global derived "${dropbox}/development/figures/nyc_charter"

*-------------------------------------------------------------------------------
*Prep Geography
*-------------------------------------------------------------------------------
import delim "${data}/nyc_zap/zapprojectbbls_20240101csv/zap_projectbbls", clear bindquote(strict)
tempfile bbls
save `bbls'



*-------------------------------------------------------------------------------
*Explore Filings
*-------------------------------------------------------------------------------
*Load in Data
import delim "${data}/nyc_zap/zapprojects_20240101csv/zap_projects", clear bindquote(strict)

*Clean Dates
foreach date in app_filed_date noticed_date certified_referred approval_date completed_date {
	gen has_`date' = !mi(`date')
	gen temp = date(`date', "YMD")
	drop `date'
	rename temp `date'
	format `date' %td
}

gen year = year(certified_referred)

gen approved = project_status == "Complete"
*keep if ulurp_non == "ULURP"


*merge 1:m project_id using `bbls'


*-------------------------------------------------------------------------------
*Clean Project Brief 
*-------------------------------------------------------------------------------
replace project_brief = strlower(project_brief)


gen c_zoning = strpos(project_brief, "zoning") != 0 | strpos(project_brief, "rezone") != 0 | strpos(project_brief, "zm") != 0 | strpos(project_brief, "za") != 0 
gen c_dispo = strpos(project_brief, "dispo") != 0 | strpos(project_brief, "sale of") != 0
gen c_acq = strpos(project_brief, "acq") != 0 
gen c_map =  strpos(project_brief, "map") != 0 
gen c_spec_perm = strpos(project_brief, "special permit") != 0 | strpos(project_brief, "spec perm") != 0 
gen c_sidewalk =  strpos(project_brief, "sidewalk") != 0
gen c_change =  strpos(project_brief, "change") != 0

egen classified = rowtotal(c_*)
replace classified = classified != 0
sum classified 

br if classified == 0 

br if c_zoning ==1 


binscatter c_zoning c_dispo year, line(connect) discrete 

*Categories 
gen sanitation = strpos(project_brief, "sanit") != 0 
gen homeless = strpos(project_brief, "homeless") != 0 

keep if approved == 1 
collapse (rawsum) approved c_zoning c_dispo c_acq c_change, by(year)
keep if year > 1980 
tw 	(connect c_dispo year) /// 
(connect c_zoning year) /// 
(connect c_acq year) /// 
(connect c_change year) 
e
tw (connect approved year)
e


