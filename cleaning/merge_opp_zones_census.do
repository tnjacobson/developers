*Exploring NYC QOZs

global data "${dropbox}/development/data"
global output "${dropbox}/development/figures"

*-------------------------------------------------------------------------------
*Load in List of Opp Zones
*-------------------------------------------------------------------------------
*List of Opp Zones 
import excel "${data}/raw/opp_zones/designated-qozs.12.14.18.xlsx", clear
keep C 
rename C tract_geoid 
drop if _n<= 4
gen state = substr(tract_geoid,1,2)
gen county = substr(tract_geoid,3,3)
gen tract = substr(tract_geoid,6,6)
destring state county tract, replace force
gen qoz = 1 
drop tract_geoid
tempfile opp_zones
save `opp_zones'



*Load in Census Demographics 
import delim "${data}/raw/opp_zones/acs2011_2015/nhgis0018_csv/nhgis0018_ds216_20155_tract.csv", clear varnames(1)

*Tract IDS 
drop state county 
rename (statea countya tracta) (state county tract)
rename (ad2de001 ad2de002) (pov_status pov)
gen pov_rate = pov/pov_status
rename (ad4le001) (med_income)

keep state county tract pov_rate med_income

merge 1:1 state county tract using `opp_zones', keep(1 3) nogen
replace qoz = 0 if mi(qoz)

save "${data}/derived/opp_zones/opp_zone_census", replace



gen nyc = inlist(county, 5, 47,67, 81, 85) & state == 36
binscatter qoz med_income if nyc == 1, line(connect)
