
global data "${dropbox}/development/data/raw/nyc_housing"
global export "${dropbox}/development/figures/nyc_charter"


*-------------------------------------------------------------------------------
*Time Series of Land Use Applications
*-------------------------------------------------------------------------------

*Load in Data
import delim "${data}/nyc_zap/zapprojects_20240101csv/zap_projects", clear bindquote(strict)


*Cleaning Up Dates:
foreach var in app_filed_date approval_date completed_date certified_referred {
	gen has_`var' = !mi(`var')
	
}


gen date = date(certified_referred, "YMD")
gen year = year(date)
gen count = 1 

*keep if project_status == "Complete"
gen approve = project_status == "Complete"
replace project_brief = strlower(project_brief)

gen dispo = 0 
replace dispo = 1 if strpos(project_brief, "dispo") != 0
gen acq = 0 
replace acq = 1 if strpos(project_brief, "acq") != 0

gen shelter = strpos(project_brief, "shelter") != 0
replace shelter = 1 if strpos(project_brief, "homeless") != 0

gen jail = strpos(project_brief, "jail") != 0
replace jail = 1 if strpos(project_brief, "prison") != 0

gen industry = strpos(project_brief, "indus") != 0
replace industry = 1 if strpos(project_brief, "factory") != 0

gen dispo_acq = acq == 1 | dispo == 1 

keep if approve  == 1 

collapse (rawsum) count dispo_acq (mean) dispo, by(year ulurp_non)
gen count_other = count - dispo_acq 


tw (connect count_other  year if ulurp_non == "ULURP" & year != 2011 & year>= 1977)  ///
(connect dispo_acq  year if ulurp_non == "ULURP" & year != 2011 & year>= 1977) , ///
xline(1989.5, lpattern(dash) lcolor(grey%60)) ///
ytitle("Approved Land Use Changes") ///
xtitle("") ///
legend(order(1 "Non Transaction Changes" 2 "Dispositions and Acqusitions") ///
	ring(0) pos(2) col(1) size(medium))
graph export "${export}/ts_dispo.pdf", replace

e

tw (connect count_dispo year if ulurp_non == "ULURP") ///
(connect count_other year if ulurp_non == "ULURP") , ///
xline(1989.5, lpattern(dash) lcolor(grey%60)) ///
ytitle("Land Use Changes") ///
xtitle("")

e
tw (connect count year if year != 2011 & year>= 1977& ulurp_non == "ULURP"), ///
xline(1989.5, lpattern(dash) lcolor(grey%60)) ///
ytitle("Land Use Changes") ///
xtitle("")

graph export "${export}/ts_ulurp.pdf", replace

*Version with Non-ULURP
tw (connect count year if year != 2011 & year>= 1977& ulurp_non == "ULURP") ///
(connect count year if year != 2011 & year>= 1977& ulurp_non == "Non-ULURP"), ///
xline(1989.5, lpattern(dash) lcolor(grey%60)) ///
ytitle("Land Use Changes") ///
xtitle("") ///
legend(order(1 "ULURP" 2 "Non-ULURP") col(1) ring(0) pos(2) size(medium))

graph export "${export}/ts_ulurp_non.pdf", replace

*-------------------------------------------------------------------------------
*Looking at Rejection Rates
*-------------------------------------------------------------------------------
import delim "${data}/nyc_zap/zapprojects_20240101csv/zap_projects", clear bindquote(strict)
gen date = date(certified_referred, "YMD")
gen year = year(date)
gen failed = inlist(project_status, "Terminated", "Withdrawn-Other")
keep if !mi(ulurp_non)

collapse (mean) failed, by(year ulurp_non)

tw (connect failed year if year != 2011 & year>= 1977& ulurp_non == "ULURP") ///
(connect failed year if year != 2011 & year>= 1977& ulurp_non == "Non-ULURP"), ///
xline(1989.5, lpattern(dash) lcolor(grey%60)) ///
ytitle("Failed Application") ///
xtitle("") ///
legend(order(1 "ULURP" 2 "Non-ULURP") col(1) ring(0) pos(2) size(medium))

graph export "${export}/rejection_rate.pdf", replace


