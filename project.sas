**************************************************************************
**************************************************************************
**************************************************************************
Importing, processing, making transformations, and creating dummy variables;


PROC IMPORT DATAFILE='2023-2024 NBA Player Stats - Regular.csv'
OUT=NBA2324_Regular_Season_Stats
DBMS=CSV
REPLACE;
GETNAMES=YES;
DATAROW=2;
DELIMITER = ';';
RUN;


DATA newStats;
set NBA2324_Regular_Season_Stats;
if PTS > 0 then logPTS = log(PTS);
else logPTS = .;
RUN;

* Creating dummy variables for the different positions;
data newStats;
set newStats;

dPosition1 = 0;
if Pos = 'SG'    then  dPosition1 = 1;
if Pos = 'SG-PG' then  dPosition1 = 1;

dPosition2 = 0;
if Pos = 'SF'    then  dPosition2 = 1;
if Pos = 'SF-SG' then  dPosition2 = 1;
if Pos = 'SF-PF' then  dPosition2 = 1;

dPosition3 = 0;
if Pos = 'PF'    then  dPosition3 = 1;
if Pos = 'PF-SF' then  dPosition3 = 1;
if Pos = 'PF-C'  then  dPosition3 = 1;

dPosition4 = 0;
if Pos = 'C'     then  dPosition4 = 1;
if Pos = 'C-PF'  then  dPosition4 = 1;

dPosition = 0;
if Pos = 'SG'    then  dPosition = 1;
if Pos = 'SG-PG' then  dPosition = 1;
if Pos = 'SF'    then  dPosition = 2;
if Pos = 'SF-SG' then  dPosition = 2;
if Pos = 'SF-PF' then  dPosition = 2;
if Pos = 'PF'    then  dPosition = 3;
if Pos = 'PF-SF' then  dPosition = 3;
if Pos = 'PF-C'  then  dPosition = 3;
if Pos = 'C'     then  dPosition = 4;
if Pos = 'C-PF'  then  dPosition = 4;
RUN;
PROC PRINT;
RUN;

**************************************************************************
**************************************************************************
************************************************************************** 
DATA EXPLORATION

* Boxplots;
TITLE "Points by Positions";
PROC SGPLOT;
VBOX PTS / category = dPosition;
RUN;

* Histogram;
TITLE "Histogram of Points";
PROC UNIVARIATE; 
var PTS;
HISTOGRAM / NORMAL (mu = est sigma = est);
RUN;

* Scatterplot;
TITLE "Points Scatterplot";
PROC SGSCATTER;
MATRIX PTS dPosition1 dPosition2 dPosition3 dPosition4 age G; 
*MATRIX PTS GS MP FG FGA FG_;
*MATRIX PTS _3PA _3P_ _2P _2PA _2P_;
*MATRIX PTS eFG_ FT FTA FT_ ORB DRB;
*MATRIX PTS TRB AST STL BLK TOV PF;
RUN;

TITLE "Correlation Table";
PROC CORR;
VAR PTS dPosition1 dPosition2 dPosition3 dPosition4 age G GS MP FG FGA FG_
_3PA _3P_ _2P _2PA _2P_ eFG_ ORB DRB TRB AST STL BLK TOV PF;
RUN;


**************************************************************************
**************************************************************************
************************************************************************** 
Analysis Stage;


* Linear Regression;
TITLE "Residual Analysis";
PROC REG;
MODEL PTS = dPosition1 dPosition2 dPosition3 dPosition4 Age G GS MP FG FGA FG_ _3P _3PA _3P_ _2P _2PA
_2P_ eFG_ FT FTA FT_ ORB DRB TRB AST STL BLK TOV PF / vif;
PLOT student.*(predicted.);
PLOT npp.*student.;
RUN;
* the residuals show a curve and the normality plot is TERRIBLE
We need a transformation;

*******************************************************************************************************************
*******************************************************************************************************************
*******************************************************************************************************************

LOG;

TITLE "Histogram of Points";
PROC UNIVARIATE data = newStats; 
var logPTS;
HISTOGRAM / NORMAL (mu = est sigma = est);
RUN;


TITLE "PPG by Positions";
PROC SGPLOT data = newStats;
VBOX logPTS / category = dPosition;
RUN;

TITLE "Correlation Table";
PROC CORR;
VAR logPTS dPosition1 dPosition2 dPosition3 dPosition4 age G GS MP FG FGA FG_
_3PA _3P_ _2P _2PA _2P_ eFG_ ORB DRB TRB AST STL BLK TOV PF;
RUN;


TITLE "Points Scatterplot";
PROC SGSCATTER data = newStats;
*MATRIX logPTS dPosition1 dPosition2 dPosition3 dPosition4 age G; 
*MATRIX logPTS GS MP FG FGA FG_;
*MATRIX logPTS _3PA _3P_ _2P _2PA _2P_;
*MATRIX logPTS eFG_ FT FTA FT_ ORB DRB;
MATRIX logPTS TRB AST STL BLK TOV PF;
RUN;
* Some are linear. A lot of polynomail;

PROC REG;
Model logPTS = dPosition1 dPosition2 dPosition3 dPosition4 age G GS MP FG FGA FG_ _3PA _3P_
_2P _2PA _2P_ eFG_ FT FTA FT_ ORB DRB TRB AST STL BLK TOV PF;
PLOT student.*(predicted.);
PLOT npp.*student.;
RUN;
*normality plot is a lot better now;

*since the assumptions are better now, we can remove multicollinearity and then delete outliers and influential points;
PROC REG;
Model logPTS = dPosition1 dPosition2 dPosition3 dPosition4 age G GS MP FG FGA FG_ _3PA _3P_
_2P _2PA _2P_ eFG_ FT FTA FT_ ORB DRB TRB AST STL BLK TOV PF /vif;
*PLOT student.*(predicted.);
*PLOT npp.*student.;
RUN;

*deleting FGA;
PROC REG;
Model logPTS = dPosition1 dPosition2 dPosition3 dPosition4 age G GS MP FG FG_ _3PA _3P_
_2P _2PA _2P_ eFG_ FT FTA FT_ ORB DRB TRB AST STL BLK TOV PF /vif;
PLOT student.*(predicted.);
PLOT npp.*student.;
RUN;

*deleting FGA, TRB;
PROC REG;
Model logPTS = dPosition1 dPosition2 dPosition3 dPosition4 age G GS MP FG FG_ _3PA _3P_
_2P _2PA _2P_ eFG_ FT FTA FT_ ORB DRB AST STL BLK TOV PF /vif;
PLOT student.*(predicted.);
PLOT npp.*student.;
RUN;

*deleting FGA, TRB, FG;
PROC REG;
Model logPTS = dPosition1 dPosition2 dPosition3 dPosition4 age G GS MP FG_ _3PA _3P_
_2P _2PA _2P_ eFG_ FT FTA FT_ ORB DRB AST STL BLK TOV PF /vif;
PLOT student.*(predicted.);
PLOT npp.*student.;
RUN;

*deleting FGA, TRB, FG, _2PA;
PROC REG;
Model logPTS = dPosition1 dPosition2 dPosition3 dPosition4 age G GS MP FG_ _3PA _3P_
_2P _2P_ eFG_ FT FTA FT_ ORB DRB AST STL BLK TOV PF /vif;
PLOT student.*(predicted.);
PLOT npp.*student.;
RUN;

*deleting FGA, TRB, FG, _2PA, FTA;
PROC REG;
Model logPTS = dPosition1 dPosition2 dPosition3 dPosition4 age G GS MP FG_ _3PA _3P_
_2P _2P_ eFG_ FT FT_ ORB DRB AST STL BLK TOV PF /vif;
PLOT student.*(predicted.);
PLOT npp.*student.;
RUN;


*deleting FGA, TRB, FG, _2PA, FTA, FG_;
PROC REG;
Model logPTS = dPosition1 dPosition2 dPosition3 dPosition4 age G GS MP _3PA _3P_
_2P _2P_ eFG_ FT FT_ ORB DRB AST STL BLK TOV PF /vif;
PLOT student.*(predicted.);
PLOT npp.*student.;
RUN;


*deleting FGA, TRB, FG, _2PA, FTA, FG_, MP;
PROC REG;
Model logPTS = dPosition1 dPosition2 dPosition3 dPosition4 age G GS _3PA _3P_
_2P _2P_ eFG_ FT FT_ ORB DRB AST STL BLK TOV PF /vif;
PLOT student.*(predicted.);
PLOT npp.*student.;
RUN;
* Multicollinearity is solved now. Now lets focus on outliers and influential points;

*R^2 = .9148. Adj-R^2 = .9122;
PROC REG;
Model logPTS = dPosition1 dPosition2 dPosition3 dPosition4 age G GS _3PA _3P_
_2P _2P_ eFG_ FT FT_ ORB DRB AST STL BLK TOV PF / influence r;
PLOT student.*(predicted.);
PLOT npp.*student.;
RUN;

data logDel;
set newStats;
if _n_ in (15, 31, 118, 160, 172, 187, 221, 230, 235, 
309, 341, 377, 378, 462, 482, 491, 570, 607, 618, 636, 
656, 720) then delete;
RUN;

*R^2 = .9291. Adj-R^2 = .9269;
PROC REG data = logDel;
Model logPTS = dPosition1 dPosition2 dPosition3 dPosition4 age G GS _3PA _3P_
_2P _2P_ eFG_ FT FT_ ORB DRB AST STL BLK TOV PF / influence r;
PLOT student.*(predicted.);
PLOT npp.*student.;
RUN;

*another layer to delete;
data logDelDel;
set logDel;
if _n_ in (15, 86, 151, 161, 197, 202, 217, 227, 267, 
327, 350, 476, 631, 636) then delete;
RUN;

*R^2 = .9340. Adj-R^2 = .9319; 
PROC REG data = logDelDel;
Model logPTS = dPosition1 dPosition2 dPosition3 dPosition4 age G GS _3PA _3P_
_2P _2P_ eFG_ FT FT_ ORB DRB AST STL BLK TOV PF / influence r;
PLOT student.*(predicted.);
PLOT npp.*student.;
RUN;

data logDelDelDel;
set logDelDel;
if _n_ in (97, 140, 233, 304, 310, 551, 622, 639, 656,
666, 685) then delete;
RUN; 

*R^2 = .9374, Adj-R^2 = .9354;
PROC REG data = logDelDelDel;
Model logPTS = dPosition1 dPosition2 dPosition3 dPosition4 age G GS _3PA _3P_
_2P _2P_ eFG_ FT FT_ ORB DRB AST STL BLK TOV PF / influence r;
PLOT student.*(predicted.);
PLOT npp.*student.;
RUN;
* didn't improve much so we'll stop here;

*Full Model with assumptions and diagnostics fixed;
TITLE "Final Model";
PROC REG data = logDelDelDel;
Model logPTS = dPosition1 dPosition2 dPosition3 dPosition4 age G GS _3PA _3P_
_2P _2P_ eFG_ FT FT_ ORB DRB AST STL BLK TOV PF;
RUN;

*******************************************************************************************************************
*******************************************************************************************************************
Splitting and testing phase;
TITLE "Test and Train Sets";
PROC SURVEYSELECT data = logDelDelDel out = xv_all seed = 237321
samprate = 0.75 outall;
RUN;
PROC PRINT data = xv_all;
RUN;


data NBAtraining (where = (Selected = 1));
set xv_all;
run;
PROC PRINT data = NBAtraining;
RUN;

data xv_all;
set xv_all;
if selected then new_y = logPts;
RUN;
PROC PRINT data = xv_all;
RUN;


PROC REG data = xv_all;
MODEL new_y = dPosition1 dPosition2 dPosition3 dPosition4 age G 
GS _3PA _3P_ _2P _2P_ eFG_ FT FT_ ORB DRB AST STL BLK TOV PF / 
	selection = cp;
* dPosition1 dPosition2 dPosition3 dPosition4 G GS _3PA
_3P_ _2P eFG_ ORB DRB STL PF FT_;

MODEL new_y = dPosition1 dPosition2 dPosition3 dPosition4 age G 
GS _3PA _3P_ _2P _2P_ eFG_ FT FT_ ORB DRB AST STL BLK TOV PF / 
	selection = backward;
RUN;
* dPosition1 dPosition2 dPosition3 dPosition4 G GS _3PA
_3P_ _2P eFG_ ORB DRB STL PF;

* Model 1 Final Equation;
PROC REG data = xv_all;
MODEL new_y = dPosition1 dPosition2 dPosition3 dPosition4 G GS _3PA
_3P_ _2P eFG_ ORB DRB STL PF FT_;
RUN;

* Model 2 Final Equation;
PROC REG data = xv_all;
MODEL new_y = dPosition1 dPosition2 dPosition3 dPosition4 G GS _3PA
_3P_ _2P eFG_ ORB DRB STL PF;
RUN;

* Check for assumptions and diagnostics;
* R^2 = .9363. Asj-R^2 = .9344;
PROC REG data = xv_all;
MODEL new_y = dPosition1 dPosition2 dPosition3 dPosition4 G GS _3PA
_3P_ _2P eFG_ ORB DRB STL PF FT_ / influence r;
PLOT student.*(predicted.);
PLOT npp.*student.;
RUN;
* multicolleanrity is okay;
* 23, 354, 361, 403, 413, 426, 611, 672 are outliers/influential points;
* residuals/assumptions are okay. mostly polynomial;

* R^2 = .9322. Adj-R^2 = .9303;
PROC REG data = xv_all;
MODEL new_y = dPosition1 dPosition2 dPosition3 dPosition4 G GS _3PA
_3P_ _2P eFG_ ORB DRB STL PF / influence r;
PLOT student.*(predicted.);
PLOT npp.*student.;
* multicolleanrity is okay;
* 23, 390, 403, 426, 551, 617 are outliers/influential points;
* residuals/assumptions are okay. mostly polynomial;
RUN;

data finalDel;
set xv_all;
if _n_ in (23, 354, 361, 403, 426, 611, 672,
390, 551, 617) then delete;
RUN;


PROC REG data = finalDel;
* R^2 = .9415 Adj-R^2 = .9397;
MODEL new_y = dPosition1 dPosition2 dPosition3 dPosition4 G GS _3PA
_3P_ _2P eFG_ ORB DRB STL PF FT_ / influence r;
PLOT student.*(predicted.);
PLOT npp.*student.;
RUN;

* R^2 = .9380. Adj-R^2 = .9362;
PROC REG data = finalDel;
MODEL new_y = dPosition1 dPosition2 dPosition3 dPosition4 G GS _3PA
_3P_ _2P eFG_ ORB DRB STL PF /influence r;
PLOT student.*(predicted.);
PLOT npp.*student.;
RUN;

* little improvements so we'll stop there;
* all assumptions and diagnostics are good;
PROC PRINT data = finalDel;
RUN;

TITLE "Final-final Model";
PROC REG data = finalDel;
MODEL new_y = dPosition1 dPosition2 dPosition3 dPosition4 G GS _3PA
_3P_ _2P eFG_ ORB DRB STL PF FT_;
output out = outm1(where = (new_y = .)) p = yhat;


MODEL new_y = dPosition1 dPosition2 dPosition3 dPosition4 G GS _3PA
_3P_ _2P eFG_ ORB DRB STL PF;
output out = outm2(where = (new_y = .)) p = yhat;
RUN;



*Model 1;
TITLE "Difference between observed and predicted in test set";
data outm1_sum;
set outm1;
d = logPTS - yhat;
absd = abs(d);
RUN;

PROC SUMMARY data = outm1_sum;
var d absd;
output out = outm1_stats std(d) = rmse mean(absd) = mae;
RUN;
PROC PRINT data = outm1_stats;
TITLE "Validation statistics for model";
RUN;
PROC CORR data = outm1;
var logPTS yhat;
RUN;

*Model 2;
data outm2_sum;
set outm2;
d = logPTS - yhat;
absd = abs(d);
RUN;

PROC SUMMARY data = outm2_sum;
var d absd;
output out = outm2_stats std(d) = rmse mean(absd) = mae;
RUN;
PROC PRINT data = outm1_stats;
TITLE "Validation statistics for model";
RUN;
PROC CORR data = outm2;
var logPTS yhat;
RUN;


*Predictions;
data pred;
input dPosition1 dPosition2 dPosition3 dPosition4 G GS _3PA _3P_ _2P eFG_ ORB DRB STL PF FT_;
datalines;
1 0 0 0 50 45 2 0.50 6 0.52 3 4 1 4 0.75
0 0 0 0 23 17 5 0.32 3 0.34 0.2 0.8 0.2 0.4 0.67
0 1 0 0 65 65 5 0.45 6 0.59 1.3 5.9 0.9 2.1 0.89
0 0 0 0 58 2 5 0.28 7 0.21 0.1 1.3 0.2 1.5 0.65
0 0 0 1 60 58 2 0.42 10 0.78 2.5 10.8 1.7 4.1 0.98
0 0 0 1 45 40 1.3 0.33 8 0.67 2.4 8.1 1.1 4.3 .72
0 0 1 0 45 40 1.3 0.33 8 0.67 2.4 8.1 1.1 4.3 .72
0 1 0 0 45 40 1.3 0.33 8 0.67 2.4 8.1 1.1 4.3 .72
1 0 0 0 45 40 1.3 0.33 8 0.67 2.4 8.1 1.1 4.3 .72
0 0 0 0 45 40 1.3 0.33 8 0.67 2.4 8.1 1.1 4.3 .72
;
run;
PROC PRINT;
RUN;

data prediction;
set pred finalDel;
PROC PRINT data = prediction (obs = 99);
RUN;

PROC REG data = prediction;
MODEL new_y = dPosition1 dPosition2 dPosition3 dPosition4 G GS _3PA
_3P_ _2P eFG_ ORB DRB STL PF FT_ / p clm cli;
RUN;

PROC REG data = prediction;
MODEL new_y = dPosition1 dPosition2 dPosition3 dPosition4 G GS _3PA
_3P_ _2P eFG_ ORB DRB STL PF / p clm cli;
RUN;



