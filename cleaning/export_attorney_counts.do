*Explore Attorneys


global data "${dropbox}/development/data/intermediate"
global derived "${dropbox}/development/data/derived"

global graphics "${dropbox}/development/figures/rezoning"


*-------------------------------------------------------------------------------
*Load in Data
*-------------------------------------------------------------------------------
import delim "${data}/agendas_clean", clear varnames(1)

gen count = 1
collapse (rawsum) count, by(attorney)
gsort -count

export delim "${derived}/attorney_counts.csv", replace


replace attorney = strlower(attorney)

*Finding Most Popular Attorneys

*banks
gen f_banks = strpos(attorney, "banks") != 0 | strpos(attorney, "ftikas") | strpos(attorney, "barnes")

*Schain Banks
gen f_schain_banks = (strpos(attorney, "banks") != 0 & strpos(attorney, "schain") != 0) ///
			| strpos(attorney, "manic") != 0 | (strpos(attorney, "william") != 0 &  strpos(attorney, "banks") != 0)
replace f_banks = 0 if f_schain_banks == 1

*Moore
gen f_mccarthy_duffy = (strpos(attorney, "moore") != 0) | (strpos(attorney, "duffy") != 0) ///
						 | strpos(attorney, "mccarthy") != 0


*Acosta
gen f_acosta_ezgur = strpos(attorney, "acosta") != 0 | strpos(attorney, "ezgur") != 0 | strpos(attorney, "castro") != 0

*Kupiec
gen f_kupiec = strpos(attorney, "kupiec") != 0


*Kolpak
gen f_kolpak = strpos(attorney, "kolpak") != 0

*Gordon and Pikarski
gen f_gordon_pikarski = strpos(attorney, "pikarski") != 0 | strpos(attorney, "gordon") != 0 

*Applegate 
gen f_applegate = strpos(attorney, "applegate") != 0 | strpos(attorney, "friedland") != 0  ///
	| strpos(attorney, "thorne-thomsen") != 0
	
*Lauer
gen f_lauer = strpos(attorney, "lauer") != 0 | strpos(attorney, "laver") != 0

*Piper 
gen f_piper = strpos(attorney, "piper") != 0 | strpos(attorney, " dla ") != 0 ///
				| strpos(attorney, "jahnke") != 0
				
gen f_george = strpos(attorney, "george") != 0  & strpos(attorney, "georges") == 0 

gen f_leroy =  strpos(attorney, "leroy") != 0 | strpos(attorney, " neal ") != 0


*Create a Firm ID variable
gen firm = ""

ds f_*
foreach var in `r(varlist)' {
	di "1"
	replace firm = "`var'" if `var' == 1
}

replace firm = subinstr(firm, "f_", "",.)
replace firm = attorney if mi(firm)


collapse (rawsum) count, by(firm)
drop if firm == "na"


sum count 
gen share = count / `r(sum)'
gsort -share

e


local mylist "item1 item2 item3"
local mylist_with_commas : list mylist, separator(",")

