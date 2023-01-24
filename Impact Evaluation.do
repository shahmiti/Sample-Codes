/********************************************************************************
Name: Miti Shah
Date: Dec-10-2022

Project Title: Household Decision Making (bargaining) and excess to fertility 

Objective: Replicate results to assess sample balance across the intervention arms, run regressions to test two hypothesis and determine any heterogenous treatment effects
********************************************************************************
********************************************************************************/

clear


********************************************************************************
*Setting file path
********************************************************************************

global user "/Users/mitishah"

global data "$user/Downloads/Final_Project/Data"

global tables "$user/tables"

*Checking datasets:

	use "$data/fertility_regressions.dta", clear
	drop if missing(respondentid)
	isid respondentid
	save "$data/fertility_regressions.dta", replace

	use "$data/fertility_summarystats.dta", clear
	drop if missing(respondentid)
	isid respondentid
	save "$data/fertility_summarystats.dta", replace

* Merge:

	use "$data/fertility_regressions.dta", clear
	merge m:1 respondentid using "$data/fertility_summarystats.dta"
	drop _merge
	save "$data/fertility_merged.dta", replace


********************************************************************************
*Setting globals
********************************************************************************

*create treatment assignment
gen treat_couple = .
replace treat_couple = 1 if Icouples == 1 & ittsample4 == 1 //couple treatment
replace treat_couple = 0 if Icouples == 0 & ittsample4 == 1
tab treat_couple //individual assignment

* Age < 40
gen n_age40 = .
replace n_age40 = 1 if age40 == 0
replace n_age40 = 0 if age40 == 1
	
global base_char "step7_usingany step3_numchildren step7_injectables step7_pill step7_hormone tried_inj_base timesincelastbirth hus3_3_ageinyears hus1_highestschool hus12_ideal husmonthlyinc earned_lastmth husb40 e26violentpressure decide_sav hus_money"

**Creating globals for regression:

global control "a16_3_ageinyrs hus3_3_ageinyears school hus1_highestschool step3_numchildren e1_ideal hus12_ideal step7_injectables step7_pill step7_usingany monthlyinc husmonthlyinc fertdesdiff2 mostfertile n_age40 timesincelastbirth diffht_wtchild i.compound_num"

global control_mi = "d_a16_3_ageinyrs d_hus3_3_ageinyears d_school d_hus1_highestschool d_step3_numchildren d_e1_ideal d_hus12_ideal d_monthlyinc d_husmonthlyinc d_fertdesdiff2 d_mostfert d_age40 d_step7* d_times d_diffht_wtchild d_compound_num"  //dummy of all missing variables


********************************************************************************
*Checking Balance
********************************************************************************

iebaltab $base_char, grpvar(treat_couple) pttest rowvarlabels save("$tables\Balance.xlsx") replace


********************************************************************************
*Checking Attrition
********************************************************************************


gen attrit = .
replace attrit = 0 if ittsample4 == 1 & ittsample4_follow == 1
replace attrit = 1 if ittsample4 == 1 & ittsample4_follow == 0

tab attrit

tab treat_couple, sum(attrit)

*Relation of attrition with baseline charc

iebaltab $base_char, grpvar(attrit) pttest rowvarlabels save("$tables\Q4_Attrition_1.xlsx") replace // no significant difference in types of people attiring by treatment group.

*variation in attrition by treatment group

reg attrit treat_couple, robust //attrition rate is 1.7 percentage points lower in the couple treatment group compared to individual group, but not statistically significant to interpret. 

*charac of people attriting differ by treatment group

gen school_treat = treat_couple*school
reg attrit treat_couple school school_treat  $control $control_mi 
est sto Att1 

gen step7_usingany_treat = treat_couple*step7_usingany
reg attrit treat_couple step7_usingany step7_usingany_treat  $control $control_mi 
est sto Att2

gen monthlyinc_treat= treat_couple*monthlyinc
reg attrit treat_couple monthlyinc monthlyinc_treat  $control $control_mi 
est sto Att3

gen timesincelastbirth_treat = treat_couple*timesincelastbirth
reg attrit treat_couple timesincelastbirth timesincelastbirth_treat  $control $control_mi 
est sto Att4



esttab Att1 Att2 Att3 Att4 using "mydoc.xlsx", se


********************************************************************************
* Regression Results
********************************************************************************

***Creating variables:

replace e18maxnumber=. if e18maxnumber<0
replace e7maxnumber=. if e7maxnumber<0
replace e19minnumber=. if e18maxnumber<0
replace e8minnumber=. if e8minnumber<0


gen h_more_w_ideal = 1 if e12_hus_ideal > e1_ideal // husband's ideal number of children is more than the wife
replace h_more_w_ideal = 0 if e12_hus_ideal < e1_ideal
replace h_more_w_ideal = . if d_e12_hus_ideal == 1
 
gen equal_ideal = (e12_hus_ideal==e1_ideal) // husband & wife's ideal number of children are equal
replace equal_ideal = . if d_e12_hus_ideal==1 

gen h_more_w_max = (e18maxnumber>e7maxnumber)  //(wife believes) husband can manage more children than her
replace h_more_w_max = . if (e18maxnumber==. | e7maxnumber==.)

gen h_more_w_min = (e19minnumber_hus>e8minnumber) // wife believes minimum num of children husband needs more than her
replace h_more_w_min = . if e19minnumber_hus ==. | e8minnumber == .  

gen h_wantsmore_max = ((e18maxnumber-currentnumchildren)>0) // wife believes husband wants more children then they currently have
replace h_wantsmore_max = . if e18maxnumber==. | currentnumchildren==.
 
gen h_wantsmore_ideal = (((e12_hus_ideal-currentnumchildren)>0) | e17morekids>0 ) //wife believes husband's ideal is more than they currently have
replace h_wantsmore_ideal = . if (d_e12_hus_ideal==1 | currentnumchildren==.) & (e17morekids==-9)

gen w_wantsmore = ((e7maxnumber-currentnumchildren)>0) //wife wants more children then they currently have
replace w_wantsmore = . if e7maxnumber==. | currentnumchildren==.

gen h_wantsmore_comb = (h_more_w_ideal==1 | ((h_more_w_min==1 | h_more_w_max==1) & equal_ideal==1)) //both husband & wife want more children then they currently have
replace h_wantsmore_comb = . if h_more_w_ideal==. & h_more_w_min==. & h_more_w_max==. & equal_ideal==.

gen responder = ((h_more_w_min==1 | h_more_w_ideal ==1 | h_more_w_max ==1) &  h_wantsmore_ideal ==1 & wantschildin2==0)
replace responder = . if ((h_more_w_min ==. & h_more_w_ideal ==. & h_more_w_max ==.) | h_wantsmore_ideal ==. | wantschildin2==.)




*EFFECT OF PRIVATE INFORMATION TREATMENT ON HOUSEHOLDS


******Without Controls (Panel A)
	* All women
	** Column (1)
	reg usedvoucher treat_couple	// same coefficient & p-value
	est sto A1
	
	** Column (2)
	reg Ireceivedinj treat_couple	// same coefficient & p-value
	est sto A2
	
	** Column (3) & (4)
	ivregress 2sls birthyr1 (usedvoucher = treat_couple), first	// (1st stage: reg usedvoucher treat & 2nd stage: reg birth predicted vouvher) Results are slightly different as the paper does not use the normal 2nd stage *bootstrapped biprobit estimation.
	est sto A34
	
	* Responders
	* Column (5)
	reg usedvoucher treat_couple if responder == 1
	est sto A5
	
	* Column (6)
	reg Ireceivedinj treat_couple if responder == 1
	est sto A6
	
	* Nonresponders
	* Column (7)
	reg usedvoucher treat_couple if responder == 0
	est sto A7
	
	* Column (8)
	reg Ireceivedinj treat_couple if responder == 0
	est sto A8
	
	
	* Table for Panel A
	esttab A1 A2 A34 A5 A6 A7 A8


**** With Controls (Panel B)
	* All women
	** Column (1)
	reg usedvoucher treat_couple $controls $control_mi
	est sto B1
	
	** Column (2)
	reg Ireceivedinj treat_couple $controls $control_mi
	est sto B2
	
	** Column (3) & (4)
	ivregress 2sls birthyr1 (usedvoucher = treat_couple) $controls $control_mi, first
	est sto B34

	* Responders
	* Column (5)
	reg usedvoucher treat_couple $controls $control_mi if responder == 1
	est sto B5
	
	* Column (6)
	reg Ireceivedinj treat_couple $controls $control_mi if responder == 1
	est sto B6
	

	* Nonresponders
	* Column (7)
	reg usedvoucher treat_couple $controls $control_mi if responder == 0
	est sto B7
	
	* Column (8)
	reg Ireceivedinj treat_couple $controls $control_mi if responder == 0
	est sto B8
	
	
	* Table for Panel B
	esttab B1 B2 B34 B5 B6 B7 B8

	
** EFFECT OF PRIVATE INFORMATION TREATMENT ON HOUSEHOLDS: MEASURES OF WELL-BEING


gen satisfied = (j11satisfy==4 | j11satisfy==5)
replace satisfied = . if j11satisfy==.

gen healthier = (a21health==4 | a21health==5)
replace healthier = . if a21health==.


gen happier = (a22happy==4 | a22happy==5)
replace happier = . if a22happy==.

	
eststo clear
	eststo A: reg satisfied treat_couple $control $control_mi if ittsample4_follow == 1 
	sum satisfied if ittsample4_follow == 1 & treat_couple == 0 
	estadd r(mean)
	
	eststo B: reg healthier treat_couple $control $control_mi if ittsample4_follow == 1 
	sum healthier if ittsample4_follow == 1 & treat_couple == 0 
	estadd r(mean)
	
	eststo C: reg happier treat_couple $control $control_mi if ittsample4_follow == 1 
	sum happier if ittsample4_follow == 1 & treat_couple == 0 
	estadd r(mean)
	
	eststo D: reg satisfied treat_couple $control $control_mi if ittsample4_follow == 1 & responder ==1
	sum satisfied if ittsample4_follow == 1 & treat_couple == 0 & responder ==1
	estadd r(mean)
	
	eststo E: reg healthier treat_couple $control $control_mi if ittsample4_follow == 1 & responder ==1
	sum healthier if ittsample4_follow == 1 & treat_couple == 0 & responder ==1
	estadd r(mean)
	
	eststo F: reg happier treat_couple $control $control_mi if ittsample4_follow == 1 & responder ==1
	sum happier if ittsample4_follow == 1 & treat_couple ==0 & responder ==1
	estadd r(mean)
	
	eststo G: reg satisfied treat_couple $control $control_mi if ittsample4_follow == 1 & responder ==0
	sum satisfied if ittsample4_follow == 1 & Iindividual==1 & responder ==0
	estadd r(mean)
	
	eststo H: reg healthier treat_couple $control $control_mi if ittsample4_follow == 1 & responder ==0
	sum healthier if ittsample4_follow == 1 & treat_couple == 0 & responder ==0
	estadd r(mean)
	
	eststo I: reg happier Icouples $control $control_mi if ittsample4_follow == 1 & responder ==0
	sum happier if ittsample4_follow == 1 & treat_couple == 0 & responder ==0
	estadd r(mean)
	
	esttab A B C D E F G H I using "$tables\regress2.csv"

********************************************************************************
* Heterogenous Treatment Effect
********************************************************************************

	
	* Interaction term
	gen treat_responder = treat_couple * responder
	tab treat_responder, m // Responder&couple:74, other:615 obs
		
	reg usedvoucher treat_couple responder treat_responder $controls $control_mi
	est sto hetero
	
	esttab hetero



