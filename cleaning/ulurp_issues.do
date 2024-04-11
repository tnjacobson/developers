*Assess Missing BBLs


global data "${dropbox}/development/data/raw/nyc_housing"
global output "${dropbox}/development/figures/nyc_charter/data_issues"
cap mkdir "${output}"

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


merge 1:m project_id using `bbls'

gen has_geo = _merge == 3 

bys project_id: keep if _n == 1

replace project_brief = strlower(project_brief)

gen c_zoning = strpos(project_brief, "zoning") != 0 | strpos(project_brief, "rezone") != 0 | strpos(project_brief, "zm") != 0 | strpos(project_brief, "za") != 0 
gen c_dispo = strpos(project_brief, "dispo") != 0 | strpos(project_brief, "sale of") != 0
gen c_acq = strpos(project_brief, "acq") != 0 
gen c_map =  strpos(project_brief, "map") != 0 
gen c_spec_perm = strpos(project_brief, "special permit") != 0 | strpos(project_brief, "spec perm") != 0 
gen c_sidewalk =  strpos(project_brief, "sidewalk") != 0

gen c_zoning_map = c_zoning == 1 | c_map == 1 
gen c_disp_acq = c_dispo == 1 | c_acq == 1 
gen c_un = c_zoning_map == 0 & c_disp_acq == 0


*Geography by Time
binscatter has_geo year if year >= 1980, line(connect) discrete ///
xline(1989.5, lpattern(dash) lcolor(grey%60)) ytitle("Fraction with Valid Parcel") ///
xtitle("")

graph export "${output}/geo_over_time.pdf", replace

keep if ulurp_non == "ULURP"

*Geography by Time
binscatter has_geo year if year >= 1980, line(connect) discrete ///
xline(1989.5, lpattern(dash) lcolor(grey%60)) ytitle("Fraction with Valid Parcel") ///
xtitle("")

graph export "${output}/geo_over_time_ulurp.pdf", replace

keep if approved == 1

*Geography by Time
binscatter has_geo year if year >= 1980, line(connect) discrete ///
xline(1989.5, lpattern(dash) lcolor(grey%60)) ytitle("Fraction with Valid Parcel") ///
xtitle("")

graph export "${output}/geo_over_time_ulurp_complete.pdf", replace


*Looking at Time Series
gen c_sanitation = strpos(project_brief, "sanit") != 0 
gen c_homeless = strpos(project_brief, "homeless") != 0 
gen c_jail = strpos(project_brief, "jail") != 0  | strpos(project_brief, "prison") != 0 

egen c_bad = rowmax(c_sanitation c_jail c_homeless)

collapse (rawsum) approved has_geo c_*, by(year)


tw 	(connect c_disp_acq year if year >= 1980) ///
	(connect c_zoning_map year if year >= 1980 ) ///
	(connect c_un year if year >= 1980), ///
xline(1989.5, lpattern(dash) lcolor(grey%60)) ///
ytitle("Approved Changes") ///
xtitle("") ///
legend(order(1 "Public Land Transactions" 2 "Zoning" 3 "Unclassified") ///
	ring(0) pos(2) col(1) size(medium))
	
graph export "${output}/categories_over_time_ulurp_complete.pdf", replace
	
tw 	(connect c_disp_acq year if year >= 3000) ///
	(connect c_zoning_map year if year >= 1980 ), ///
xline(1989.5, lpattern(dash) lcolor(grey%60)) ///
ytitle("Approved Zoning Changes") ///
xtitle("") ///
legend(off)
graph export "${output}/zoning_over_time_ulurp_complete.pdf", replace

		
	
	e
sort year
tw 	(connect approved year ) ///
	(connect has_geo year )
	
tw (connect c_bad year)
	e
	
tw (connect c_dispo year ) 
tw (connect c_acq year ) 
tw (connect c_zoning_map year ) 
e
tw (connect c_spec_perm year if inrange(year, 1980, 2000)) 


