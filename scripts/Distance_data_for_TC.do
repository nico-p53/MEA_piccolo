
**************
**This script brings in demographic data and loads in the distance data to create destination 
*distances for each county to every county that could be visited in Michigan, inluding a stay-home 
*alternative
**************

clear
import delimited "/Users/nicolinapiccolo/Desktop/ENVS 391 /nhgis0007_ds249_20205_county.csv", rowrange(3) 
keep if state == "Michigan"
rename amvbe001 total_pop
rename amvbe002 owner_occup
rename amvbe006 owner2000_2009
rename amvbe009 rent_occup
rename amvbe013 rent2000_2009
keep gisjoin state statea county countya total_pop owner_occup owner2000_2009 rent_occup rent2000_2009

gen own_stayhome = owner2000_2009/owner_occup
gen rent_stayhome = rent2000_2009/rent_occup


import delimited "/Users/nicolinapiccolo/Desktop/ENVS 391 /educ.residence.csv", rowrange(3) 
keep if state == "Michigan"
rename ak5re022 bachelors
rename ak5re001 educ_total
rename ak5re002 nobach
rename ak5re003 nobach1
rename ak5re004 nobach2
rename ak5re005 nobach3
rename ak5re006 nobach4
rename ak5re007 nobach5
rename ak5re008 nobach6
rename ak5re009 nobach7
rename ak5re010 nobach8
rename ak5re011 nobach9
rename ak5re012 nobach10
rename ak5re013 nobach11
rename ak5re014 nobach12
rename ak5re015 nobach13
rename ak5re016 nobach14
rename ak5re017 nobach15
rename ak5re018 nobach16
rename ak5re019 nobach17
rename ak5re020 nobach18
rename ak5re021 nobach19
rename alkbe001 occup_total
rename alkbe002 owner_occup
rename alkbe006 ownerpre2010
rename alkbe007 ownerpre2010_1
rename alkbe008 ownerpre2010_2
rename alkbe009 renter_occup
rename alkbe013 renterpre2010
rename alkbe014 renterpre2010_1
rename alkbe015 renterpre2010_2

keep gisjoin state statea county countya bachelors educ_total nobach nobach1 nobach2 nobach3 nobach4 nobach5 nobach6 nobach7 nobach8 nobach9 nobach10 nobach11 nobach12 nobach13 nobach14 nobach15 nobach16 nobach17 nobach18 nobach19 occup_total owner_occup ownerpre2010 ownerpre2010_1 ownerpre2010_2 renter_occup renterpre2010 renterpre2010_1 renterpre2010_2

*****************************************************************************************************************

clear
getcensus s1501_c01_006 s1501_c01_015, sample(5) geography(county) years(2010) statefips(26) noerror
gen bach25 = s1501_c01_006*s1501_c01_015/100
gen nobach25 = s1501_c01_006 - bach25
rename s1501_c01_006 population
set obs `=_N+1'
gen non_mich = ( population==.)
tempfile mich_before
save `mich_before'

save "/Users/nicolinapiccolo/Desktop/research 2022/Mich_Before.dta", replace

getcensus s1501_c01_006 s1501_c01_015, sample(5) geography(county) years(2020) statefips(26) noerror
rename s1501_c01_015e bach25
gen nobach25 = s1501_c01_006 - bach25
rename s1501_c01_006 population
set obs `=_N+1'
gen non_mich = ( population==.)
cross using "/Users/nicolinapiccolo/Desktop/research 2022/Mich_Before.dta"

**************************************************
************Loading data for travel distance*********
**************************************************
*DESTINATION*
import delimited "/Users/nicolinapiccolo/Desktop/ENVS 391 /county_fips.csv", clear 
drop county
keep if state == "Michigan"
replace countyname = countyname+ " "
tempfile fips
save `fips'

import excel "/Users/nicolinapiccolo/Desktop/ENVS 391 /Residential populations.xlsx", sheet("MCs 10-20") firstrow clear

keep if strpos(locationdestination,"County") |strpos(locationdestination,"Catchall") 
keep if strpos(locationorigin,"County") |strpos(locationorigin,"Catchall")

replace locationdestination = subinstr(locationdestination,"Michigan","",.)
replace locationdestination = subinstr(locationdestination,",","",.)


rename locationdestination countyname
tempfile dist
save `dist'

merge m:1 countyname using `fips', nogen

gen state_dest = floor(fips/1000)
gen county_dest = fips-26000

drop countyname fips
keep if strpos(locationorigin,"County") |strpos(locationorigin,"Catchall")

replace locationorigin = subinstr(locationorigin,"Michigan","",.)
replace locationorigin = subinstr(locationorigin,",","",.)
rename locationorigin countyname 
merge m:1 countyname using `fips'
gen state_orig = floor(fips/1000)
gen county_orig = fips-26000

keep state_dest county_dest state_orig county_orig movedistance
save "/Users/nicolinapiccolo/Desktop/ENVS 391 /distance data MI.dta", replace

