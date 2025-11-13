*******************************************************************************
* ECON-2120 HW 8 Code Sample
* Author: Liam Mason
* Note: This code is from a problem set in an econometrics class I took at Georgetown. In the problem set, I work with instrumental variables to generate accurate regression models on real-world data. I have included descriptions of important variables before each problem based on the information provided in the problem and data set.
*******************************************************************************

version 19.0
clear all
set more off

cd "/Users/lmasonsc/Documents/Georgetown/Classes/Not This Semester/2024 (4)Spring/Econometrics/Stata/Data"

/* ==========================================================================
   PROBLEM 2. Alcohol and Employment
   
   abuse 				   Dummy variable indicating if individual abuses alcohol
   employ				   Dummy variable indicating if individual is employed
   mothalc, fathalc		Dummy variable indicating if mother and father abuse alcohol, respectively
   ========================================================================== */
   use "alcohol.dta", clear
   describe employ abuse mothalc fathalc age qrt1 qrt2 qrt3
   
   reg employ abuse age-qrt3, r
   * based on this OLS regression, alcohol abuse does not have a significant effect on employment at the 5% level
   * Even with these controls, we should be concerned that abuse is endogenous in the regression above because alcohol abuse is connected to unemployment. While alcohol abuse may reduce the chances of an individual's unemployment, it is also likely that being unemployed will increase the chances that an individual abuses alcohol. Therefore, it is difficult to discern which factor affects the other.
   reg abuse mothalc fathalc age-qrt3, r
   testparm mothalc fathalc
   * We want to use 'fathalc' and 'mothalc' to indicate whether a person's father and mother were alcoholics, respectivelty, as instruments for abuse. Because the F-statistic > 10, the 'rule of thumb' for instrumental variables is satisfied here.
   * To be valid instrumental variables, 'mothalc' and 'fathalc' must be (a) correlated with 'abuse,' the variable of interest, and (b) uncorrelated in any way with 'employment' except through their impact on 'abuse' (relevance and exclusion principle, respectively). Both of these conditions seem to be satisfied. 
   ivregress 2sls employ age-qrt3 (abuse = mothalc fathalc), r
   * 'abuse' is now significant at the 5% level and the magnitude becomes larger. On average, if a person abuses alcohol, they are less likely to be employed. Their chance is over 35% lower than non alcohol abusers.
   estat overid
   * Based on this, we fail to reject the null hypothesis that the instruments are valid (assuming that at least one of them are valid). 
   quietly ivregress 2sls employ age-qrt3 (abuse = mothalc fathalc), r
   predict employhat
   hist employhat
   * Generally, interpreting the value of a dummy deendent variable as a probability makes economic sense. However, probability must be in the range 0 to 1, and a linear model can predict probabilities outside of this range, as demonstrated in the histogram. Thus, it would not be appropriate to interpret these values as probabilities.
   
/* ==========================================================================
   PROBLEM 3. College GPA and Classes Skipped
   
   colGPA				   College GPA of students
   skipped				   Avg number of lectures skipped per week
   walk, bike			   Dummy variables indicating if walk, bike, or other to class
   hsGPA				      High school GPA of students
   age					   Age of students
   ACT					   ACT score of students
   business, engineer	Dummy variables indicating major
   ========================================================================== */
   use "GPA1.dta", clear
   reg colGPA skipped, r
   * For each class the student skips in a week, their GPA will decrease on average by 0.089 points. This is statistically significant at the 1% level. Economically, this is less satisfying, as 3 lectures skipped a week would only drop a student's GPA by ~0.27 points. If a student skipped 3 lectures a week on average from the same class, this means they would effectively be missing the entire class. We would expect their GPA to decrease by much more as a result. 
   * The variable 'skipped' may be endogenous, as there are many factors that could affect both 'skipped' and 'colGPA' at once. Namely, health conditions, stress level, attitude, etc. This endogeneity may lead to an inaccurate estimate of the true effect of 'skipped' on 'colGPA.'
   * Considering 'walk' and 'bike' as valid instruments for 'skipped,' we must check that they satisfy the relevance and exclusion conditions, as explained in the last problem.
   reg skipped walk, r
   reg skipped bike, r
   * Neither 'walk' or 'bike' satisfy the relevance condition. Additionally, the exclusion condition is not satisfied, as they could be correlated with the omitted variables such as stress or health. 
   reg skipped walk bike, r
   * The R-squared for the regression is 0.0682. The F-statistic is 3.55. The relevance condition weakly holds. 
   reg colGPA skipped (walk bike), r
   * Using 'walk' and 'bike' as instrumental dummy variables, we see a much greater negative coefficient on 'skipped.' However, this effect is no longer statistically significant. This further shows that 'walk' and 'bike' are weak instruments.
   reg colGPA skipped hsGPA ACT age business engineer, r
   * Controlling for these variables, the effect of skipping class on college GPA is statistically significant, but the coefficient is slightly smaller. For every lecture skipped weekly, a student's GPA would decrease by an average of 0.076 points.
   reg skipped hsGPA ACT age business engineer walk bike, r
   * This first stage of a 2SLS regression with controls shows that coefficients on walk and bike increase from the regression without controls. Both remain statistically significant, allowing us to reject the null hypothesis that walking and biking have no effect on skipping lectures at the 1% level.
   predict skippedhat
   * Saving the fitted values skippedhat for use later.
   testparm walk bike
   * However, the F-statistic of the joint test on walk and bike is still less than 10, which implies the variables are still weak instruments.
   * Relying on R^2 values alone would be insufficient, as R^2 increases as more variables are added without considering whether these variables are actually good instrumental variables. 
   ivregress 2sls colGPA hsGPA ACT age business engineer (skipped = walk bike), r
   * With 'walk' and 'bike' as instrumental variables, the coefficient on 'skipped' is decreases considerably from prior observations and is no longer statistically significant.
   estat firststage
   * estat gives us the same information as shown in the output of our first stage 2SLS regression above.
   reg colGPA skippedhat hsGPA ACT age business engineer
   * Using skippedhat as a regressor in place of skipped, the estimate of the coefficient on skipped is identical to that of the 2SLS regression, but its standard error is larger. We should use the standard error from the 2SLS regression in practice, as the 2-step process misrepresents the standard errors.
   
/* ==========================================================================
   PROBLEM 4. Demand for Fish
   
   ltotqty 					   Logarithm of total quantity sold on a particular day, t
   lavgprc 				      Logarithm of average price paid by buyers on that day
   mon, tues, wed, thurs 	Dummy variables indicating days of the week
   wave2, wave3 			   Avg max wave height over past 2 days (wave3 = 2 day lag)
   speed2, speed3 			Avg wind speed over past 2 days (speed3 = 2 day lag)
   ========================================================================== */
   use "FISH.DTA", clear
   reg ltotqty lavgprc, r
   * The OLS estimate of price elasticity of demand is: for each percentage increase in the quantity of fish sold, the price decreases by 0.49%
   reg lavgprc speed2-wave3, r
   * The variables 'wave2' and 'wave3' have the largest effect on lavgprc and are both statistically significant. Economically, the positive sign on the coefficient makes sense, as larger waves make fishing more difficult, thus raising prices.
   reg lavgprc speed2-wave3 mon-thurs, r
   testparm speed2-wave3
   * We can reject the null hypothesis that variables speed2-wave3 have no effect on average fish price, but we cannot reject the null hypothesis that variables mon-thurs have no effect on average fish price.
   ivregress 2sls ltotqty (lavgprc = speed2-wave3), r
   * Using speed2-wave3 as instruments, it appears that price has a negative effect on quantity of fish sold. This relationship is statistically significant at the 5% level. 
   ivregress 2sls ltotqty (lavgprc = mon-thurs), r
   * The standard error in this regression is much higher because we are using 'mon-thurs' as instruments despite the fact we rejected them as being valid. Additionally, this relationship is not statistically significant.
   
