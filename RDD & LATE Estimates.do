**Miti Shah
**Replicating some results RDD and LATE estimates from the paper "The Impact of Secondary Schooling in Kenya: A Regression Discontinuity Analysis" by Ozier (2018).

	clear all
	set varabbrev off
	set more off
	
*************************
* Set Up
*************************

global user "/Users/mitishah/Desktop/McCourt/Fall 2022/Impact Evaluation/Assignments & Associated Data/PS3"

use "$user/PS3_PartB_RDD.dta" , clear


******************************
*Analysis
******************************

*Visual check for discontinuity at the cut-off
histogram test, xline(0) //dense around the cut-off; leaning towards no manipulation

*Test for manipulation at the cut-off
rddensity test, plot //at p-value of 0.8, unable to reject null for ccontinuous running variable at the cut-off

*Impact of passing the test on completion of secondary school (first stage)
gen pass = test >=0
gen pass_x_test = pass * test

*Visual
binscatter secondary test, nq(100) xline(0) rd(0)
rdplot secondary test, p(1) 
*Regression
reg secondary test pass  pass_x_test , cl(test)

*Check for robustness at different bandwidths

eststo clear
reg secondary pass test pass_x_test if abs(test) < 1, cl(test)
eststo b10
reg secondary pass test pass_x_test if abs(test) < 0.9, cl(test)
eststo b09
reg secondary pass test pass_x_test if abs(test) < 0.8, cl(test)
eststo b08
reg secondary pass test pass_x_test if abs(test) < 0.7, cl(test)
eststo b07
reg secondary pass test pass_x_test if abs(test) < 0.6, cl(test)
eststo b06
reg secondary pass test pass_x_test if abs(test) < 0.5, cl(test)
eststo b05
reg secondary pass test pass_x_test if abs(test) < 0.4, cl(test)
eststo b04
reg secondary pass test pass_x_test if abs(test) < 0.3, cl(test)
eststo b03
reg secondary pass test pass_x_test if abs(test) < 0.2, cl(test)
eststo b02
reg secondary pass test pass_x_test if abs(test) < 0.1, cl(test)
eststo b01

coefplot b10 b09 b08 b07 b06 b05 b04 b03 b02 b01, keep(pass) vertical yline(0) //coefficients do not change much as the bandwidth changes and remain statistically significant; suggesting results are robust to choice of bandwidth.


*Q5
lab var test "KPCE centered at cutoff"
lab var pass "KPCE >= cutoff"
lab var pass_x_test "(KPCE >= cutoff) x KCPE"
reg secondary pass test   pass_x_test if abs(test) < 0.8, cl(test)
outreg2 using "$root\table2.xls", nocons replace lab  bdec(2) sdec(2)
reg secondary pass test   pass_x_test if abs(test) < 0.8 & female == 0, cl(test)
outreg2 using "$root\table2.xls", nocons append lab bdec(2) sdec(2)
reg secondary pass test  pass_x_test if abs(test) < 0.8 & female == 1, cl(test)
outreg2 using "$root\table2.xls", nocons append lab bdec(2) sdec(2)


*2SLS to estimate the effect of secondary school on combined reasoning and vocabulary score, rv

ivregress 2sls rv test pass_x_test female (secondary = pass) if  abs(test) < 0.8, cl(test) first


*Test for discontinuity in other variables. 
reg female pass test pass_x_test, cl(test)

*rdrobust to estimate optimal vs. fixed bandwidth results
rdrobust rv test, fuzzy(secondary) covs(female)
rdrobust rv test, fuzzy(secondary) covs(female) h(0.8) // optimal bandwidth estimated by rdrobust is much smaller than the fixed bandwidth, it is 0.462 instead of 0.8. However, the treatment effects are similar in size. They are somewhat larger in the optimal bandwidth, equal 1.139, compared to 0.82317. Both are statistically significant, both with conventional and robust standard errors.
 


