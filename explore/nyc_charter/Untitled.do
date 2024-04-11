
global data "${dropbox}/development/data/raw/nyc_housing"
global 
import delim "${data}/nyc_zap/zapprojects_20240101csv/zap_projects", clear bindquote(strict)


*Cleaning Up Dates:

foreach var in app_filed_date approval_date completed_date certified_referred {
	gen has_`var' = !mi(`var')
	
}

gen date = date(certified_referred, "YMD")
gen year = year(date)
gen count = 1 
collapse (rawsum) count, by(year)

tw (connect count year if year != 2011 & year>= 1977), ///
xline(1989.5, lpattern(dash) lcolor(grey%60)) ///
ytitle("Land Use Changes") ///
xtitle("")

