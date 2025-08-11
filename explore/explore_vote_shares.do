

global project "${dropbox}/development"
global data "${project}/data/derived"

import delim "${data}/legistar_api/all_votes_223.csv", bindquote(strict) clear

destring votevalueid, replace force 
tempfile early
save `early'

import delim "${data}/legistar_api/all_votes_224_289_on.csv", bindquote(strict) clear
destring votevalueid, replace force

tempfile mid
save `mid'

import delim "${data}/legistar_api/all_votes_290_524.csv", bindquote(strict) clear
destring votevalueid, replace 

tempfile late 
save `late'

clear 
foreach j in early mid late {
	append using ``j''
}


gen approve = .
replace approve = 1 if votevalueid == 15
replace approve = 0 if votevalueid == 12

collapse (mean) approve, by(matterid)


tempfile vote_matters 
save `vote_matters'

import delim "${data}/legistar_api/all_matters.csv", ///
 maxquotedrows(100) bindquote(strict) clear

merge 1:1 matterid using `vote_matters'

gen year = substr(matterintrodate, 1 ,4)
destring year, replace force

gen unam = approve >= .9


replace mattertitle = strlower(mattertitle)
replace mattername = strlower(mattername)

gen ulurp = strpos(mattertitle, "ulurp")!= 0 
replace ulurp = 1 if strpos(mattername, "ulurp")!= 0


binscatter approve year if ulurp == 1 & year >= 2000 & year < 2019, discrete line(connect) ///
ytitle("Average Vote Share")
