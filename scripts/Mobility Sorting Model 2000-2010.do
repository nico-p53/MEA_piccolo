*This file contains code to estimate the first stage of the aggregate sorting model.

*The code is implemented using a command line reading "sortingrum [positional arguments]" where the positional arguments is a list of six variables and a scalar. The six variables are the ID code for the destinations, the ID code for the origins, the population in the destinations, the population in the origins, an indicator for the catch-all alternative for locations outside the model, and move cost. The final argument is a scalar for the share of households that did not move, which can be defined prior to running the command, e.g. scalar share_stayhome=0.20. For example, a command could look like "sortingrum county_dest county_orig pop_dest pop_orig catchall movecost share_stayhome". 

*The output contains the mean location utilities and move cost coefficient. 

*The command summarizes part of the output for each run of the outer loop that estimates the move cost coefficient.

*If there are any locations with zero populations, add a small number to the population to get convergence.


**********************************************
****The sorting RUM command code begins here**
**********************************************
cap prog drop sortingrum
timer on 1
prog def sortingrum, rclass
display _newline as txt "Aggregate sorting (RUM-based) model" 
display _newline as txt "Inner loop iterations | Predicted share of stay-homes | Move cost coefficient"

*_dots 0
local rep 1
version 16
args id_dest				///
	id_orig					///
	pop_dest				///
	pop_orig				///
	catchall				///
	movecost				///
	share_stayhome 			
	
quietly{
	tempvar id_dest_neg share_dest share_orig sums sum_e_jk move_share move_s_pop_s delta_j delta_k e_jk diff stays_hat share_b_hat mu
	global meanutility mcparameter
	sum `id_dest'
	scalar min = r(min)
	sum `pop_orig' if `id_dest'==min
	scalar totalpop = r(mean)*r(N)	//total population across the residential origins
	scalar totallocs = r(N)		//total number of residential locations
	gen `id_dest_neg'= -1*`id_dest'
	gen `share_orig' = `pop_orig'/totalpop
	sum `pop_dest'
	gen `share_dest' = `pop_dest'/(r(mean)*r(N)/totallocs)
	gen `sums' = 0
	gen `sum_e_jk' = 0
	gen `share_b_hat' = 0
	gen `move_share' = 0
	gen `move_s_pop_s' = 0
	gen `delta_j' = 0
	gen `delta_k' = 0
	gen `diff' = 1
	scalar stays_hat = 1
	scalar tolout = 10E-4		//tolerance for outer-loop bisection
	scalar tolin = 10E-9		//tolerance for inner-loop contraction mapping
	scalar mu_max = 0.005		//maximum move cost coefficient in bisection
	scalar mu_min = 0.00001		//minimum move cost coefficient in bisection

*Beginning of the outer loop used to calculate the move cost coefficient
	local o = 1
	scalar tol_out = tolout
	while abs(stays_hat - share_stayhome) > tol_out {
		scalar sdiff = 1
		scalar mu_mid = (mu_max + mu_min)/2
		gen double `e_jk' = exp(`delta_j' - `delta_k' - mu_mid*`movecost')
		by `id_orig', s: replace `sums' = sum(`e_jk')
		by `id_orig' (`sums'), s: replace `sum_e_jk' = `sums'[_N]
		replace `move_share' = `e_jk'/`sum_e_jk'
		replace `move_s_pop_s' = `move_share'*`share_orig'
		by `id_dest', s: replace `sums' = sum(`move_s_pop_s')
		by `id_dest' (`sums'), s: replace `share_b_hat' = `sums'[_N]
		sum `move_s_pop_s' if `id_orig'==`id_dest'&`catchall'==0 //Predicted share of stay-homes should iterate to actual share of stay-homes
		scalar stays_hat = r(mean)*r(N)
		scalar sign_mid = sign(stays_hat-share_stayhome)
		scalar mu_min = cond(sign_mid<0,(mu_mid+mu_min)/2,mu_min)
		scalar mu_max = cond(sign_mid>0,(mu_mid+mu_max)/2,mu_max)

*Beginning of the inner loop used to calculate the mean site utilities
		local i = 1
		scalar tol_in = tolin
		while sdiff > tol_in {
			replace `delta_j' = `delta_j' + (ln(`share_dest') - ln(`share_b_hat')) if `id_dest'!=min
			replace `delta_k' = `delta_j' if `id_orig' ==`id_dest'
			sort `id_orig' `id_dest'
			by `id_orig', s: replace `delta_k' = `delta_k'[_n-1] if `id_orig'<`id_dest'
			sort `id_orig' `id_dest_neg'
			by `id_orig', s: replace `delta_k' = `delta_k'[_n-1] if `id_orig'>`id_dest'
			replace `e_jk' = exp(`delta_j' - `delta_k' - mu_mid*`movecost')
			drop `sum_e_jk' `share_b_hat'
			by `id_orig', s: egen `sum_e_jk' = sum(`e_jk')
			replace `move_share' = `e_jk'/`sum_e_jk'
			replace `move_s_pop_s' = `move_share'*`share_orig'
			by `id_dest', s: egen `share_b_hat' = sum(`move_s_pop_s')
			replace `diff' = abs(`share_dest' - `share_b_hat')
			sum `diff'
			scalar sdiff = r(max)
			local ++i
			scalar tol_in=tolin*10^floor(`i'/10000)			//reduces the tolerance by 10E-1 every 10000 iterations
		}	
		local ++o
		scalar tol_out=tolout*10^floor(`o'/100)				//reduces the tolerance by 10E-1 every 100 iterations
		nois display `i' %9.0g " | " %9.0g stays_hat %9.0g " | " %9.0g mu_mid 
		*nois _dots `rep++' 0
		drop `e_jk' `stay_hat'
	}
nois gen mccoefficient= mu_mid  //Estimated travel cost coefficient
gen meanutility = `delta_j'
gen share_dest=`share_dest'
gen share_pred=`share_b_hat'
collapse `pop_dest' share_dest share_pred `catchall' meanutility mccoefficient, by(`id_dest')
}
end



**********************************************
*************Importing the data***************
**********************************************
use "/Users/nicolinapiccolo/Desktop/ENVS 391 /Do Files/2000-2010 Data for sorting model stage 1.dta", clear
gen location_orig = fips_orig
gen location_dest = fips_dest
replace location_dest = 999999 if location_dest == 999
replace location_orig = 999999 if location_orig == 999
drop if  location_dest==.
preserve
keep location_orig nobach25_orig location_dest nobach25_dest nocoll_movecost coll_movecost
//Calculating the size of the catch-all pop
tempvar same
gen `same'=(location_dest==location_orig)
sum `same' if location_dest==location_orig
scalar locations = r(N)
sum nobach25_orig if location_orig!=999999
scalar total_a = r(mean)*locations
sum nobach25_dest if location_dest!=999999
scalar total_b = r(mean)*locations
replace nobach25_orig=2*(abs(total_a-total_b)) if location_orig==999999
replace nobach25_dest=2*(abs(total_a-total_b)) if location_dest==999999
drop  if nobach25_orig==.
replace coll_movecost=5000 if coll_movecost==.
replace nocoll_movecost=5000 if nocoll_movecost==.
tempfile nocollege
save `nocollege'
restore

keep location_orig bach25_orig location_dest bach25_dest nocoll_movecost coll_movecost
//Calculating the size of the catch-all pop
tempvar same
gen `same'=(location_dest==location_orig)
sum `same' if location_dest==location_orig
scalar locations = r(N)
sum bach25_orig if location_orig!=999999
scalar total_a = r(mean)*locations
sum bach25_dest if location_dest!=999999
scalar total_b = r(mean)*locations
replace bach25_orig=2*(abs(total_a-total_b)) if location_orig==999999
replace bach25_dest=2*(abs(total_a-total_b)) if location_dest==999999
drop  if bach25_orig==.
replace coll_movecost=5000 if coll_movecost==.
replace nocoll_movecost=5000 if nocoll_movecost==.
tempfile college
save `college'

**************************************************
**********Stage 1 estimation begins here**********
**************************************************
use `college', clear 
gen catch_all = (location_orig==999999)|(location_dest==999999)
scalar share_stayhome = 0.416
sortingrum location_dest location_orig bach25_dest bach25_orig catch_all coll_movecost share_stayhome
gen college = 1
tempfile utilities_bach
save `utilities_bach'

use `nocollege', clear
gen catch_all = (location_orig==999999)|(location_dest==999999)
scalar share_stayhome = 0.477
sortingrum location_dest location_orig nobach25_dest nobach25_orig catch_all nocoll_movecost share_stayhome
gen college = 0
tempfile utilities_nobach
save `utilities_nobach' 

*****
append using `utilities_bach' //Stacking the mean utilities in the college and non-college educated groups
gen year = 2005 
keep location_dest meanutility mccoefficient college year 
export excel using "/Users/nicolinapiccolo/Desktop/ENVS 391 /Data/2000-2010 First stage mean utility estimates.xls", firstrow(variables) replace
