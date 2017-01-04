# LoanGrantingBinaryClassification

In December 2016, I signed up for a Data Science Professional Project at https://courses.edx.org/courses/course-v1:Microsoft+DAT102x+1T2017/info. This course is the capstone project of the  Microsoft Professional Program for data science, and it takes the form of a Cortana intelligence competition. The goal of the competition is to predict (as a binary classification problem), whether a loan will be fully repaid. 

(expand a little on the design: public and private data and leaderboard, etc)

This document is a step-by-step documentation of my attempts at this binary classification problem.

# Public training data

I quickly explored teh public training set, entirely with the tools available in the azure ML studio. The public training data consists of approximately 77k datasets. Two variables are laond and customer ID, which probably have little predictive value. Outcome variable is 'Loan status', with the two levels  'Fully repaid' and xx. The remainng columns are categorical/string and numerical variables, with unknown predictive power. I identified two columns with 14k missing values, these columns were 'Credit Score' and 'Annual income'. This exploration took approximately five minutes and identified the following action items:

* Immediate: deal with missing values in 'Annual income' and 'Credit score'
* Possibly: drop loan and customer ID (maybe - it may also be that single customers ahve several entries)
* Possibly: deal with string and categorical values
* Possibly: scale variables (depending on the ML model)

# Initial Model

Initially, I tried to establish a very simple and non-optimized model as quickly as possible, in order to get accustomed to the whole competition pipeline. I worked entirely in the AzureML studio, as provided by the free plan. I replaced missing values in the two columns using the 'MICE' algorithms and the default value of 5 iterations. I used a simple train/test split, stratified on the 'Loan status' column, and I trained a two-class boosted decision tree model with default setting. After training, I set up a predictive web service, inserted an 'Apply sql transformation' step and submitted the competition entry.

SQL: select "Loan ID" , "Scored Labels" as Status_Pred from t1;


This very simple initial model took me on place 12 in the public leaderboard with an accurac of 68.673% (admittedly, there were only 28 submissions at the time of entry). However, and more importantly, this simple model provides a fully functional base on which I can perform subsequent feature engineering, model tuning and general improvements of prediction.

# LGBCD 1-missing-values-fixed
After an exploratory data analysis (to be posted separately), I iterated the initial two-class boosted decision tree model experiment. Briefly, I inserted an 'Execute R script' module, which replaced Current Loan Amount values of 99999999 with NAs. In the following clean-missing-data module, the such flagged values were imputed using MICE with five iterations - just as Credit score and Annual income.

In a further preprocessing step, we should deal with the Credit Score issue.

The model with fixed missing values achieved an accuracy on the private test set of 70.893508, PL 36/144

# LGBCD 1- missing-values-fixed-tuned
The previous model was trained with default settings of the two-class boosted decision tree model

CV accuracy: 0.872, AUC 0.835
PL: 71.687587

# LGBCD-2-missing-values-fixed-tuned-CSfix

CV accuracy: 0.843, AUC: 0.742
PL 71.694336 (32/278 at time of submission)

I note that all our models appear to slightly overfit on the training data - CV accuracy is higher than accuracy on the test set. This indicates a need for more regularization, possibly.

# Update: LGBCD-7- fully trained

I started working on the categorical features, and handled Years in Job, and Purpose (cut down to three indicator variables).
Train/Test Acc 0.764, AUC 0.74
PL 
as of now, untuned.

822, 851, PL

# To do: XGBoost

ON a parallel track, I am working with encouraging results with xgboost.
handling pre-trained models in azure is a pain, though.


# LGBC 11, azure only.

## Todo:

Status: 
ACC = 0.833, AUC = 0.824

* remove duplicate rows
ACC = 0.823, AUC = 0.837, PL=67

## LGBC 12...
save as .. was required because I could not update the predictive experiment.
I'm back to using R scripts.

* fix monthly debt: remove leading \\$, convert to numeric
822,838,PL 41 WTF

## LGBC 13
* purpose business loan

* deal with duplicate loan IDs: investigate, (average columns, na.rm=T)?? https://miteshgadgil.github.io/assets/Loan-Prediction-project/Data_Cleaning.html  Split-apply-combine at its best! how the heck should I do this in Azure??

we need to get down to 88910 unique loan ids
```
library(tidyverse)
df <- read.csv('LoansTrainingSetV2.csv') %>%
  distinct() %>%
  mutate(CS.exceeded = ifelse(Credit.Score>1000, 1,0)) %>%
  mutate(Credit.Score = ifelse(Credit.Score > 1000, Credit.Score/10, Credit.Score)) %>%
  mutate(Purpose = as.factor(stringr::str_to_lower(Purpose))) %>%
  arrange(desc(Loan.ID), desc(Credit.Score)) %>%
  group_by(Loan.ID) %>%
  filter(row_number()==1) %>%
  ungroup()
```
This does the trick. 

We achieve groundbreaking 43.5% on PL.

Addition of smote, 3fold CV

ACC|AUC|tree tuning set |tree parameters ABCD| PL acc
---|---|-------|---|---
843| 921|| 20/10/0.2/100|
799|  880| A=(10,20)| 20/10/0.02/100|
 859|932| B=(5,10,15)C=(0.1,0.2,0.4)|20/10/0.4/100|
882|949|D=(50,100,200)|20/10/0.4/200|
882|949|D=(50,100,200)|20/10/0.4/200|missing values imputation with mean (instead of mice)

## LGCB 14
split _before_ fix of missing values

ACC|AUC|tree tuning set |tree parameters ABCD| PL acc
---|---|-------|---|---
855| 901|| 20/10/0.2/200|43. I don't want to live on this planet anymore.

## lgbc 15

ratio added
* fix maximum open credit

## lgbc 16

started out with a completely new script.
If this fails, I will have to dbug my R script step by step.
```
df <- dataset1 %>%
    mutate(`Monthly Debt`= stringr::str_replace(`Monthly Debt`,"\\$","")) %>%
    mutate(`Monthly Debt`= as.numeric(`Monthly Debt`)) %>%
    mutate(`Months since last delinquent`= as.numeric(`Months since last delinquent`)) %>%
    mutate(`Tax Liens`= as.numeric(`Tax Liens`)) %>%
    mutate(`Maximum Open Credit`=as.numeric(`Maximum Open Credit`)) %>%
    distinct() %>%
    mutate("Years in current job" = stringr::str_replace(`Years in current job`, 
    ' years*','')) %>%
    mutate("Years in current job" = stringr::str_replace(`Years in current job`, 
    '\\+',''))%>%
    mutate("Years in current job" =  stringr::str_replace(`Years in current job`, 
    '< 1','0')) %>%
    mutate("Years in current job" = as.numeric(`Years in current job`))%>%
    mutate(Bankruptcies = as.numeric(Bankruptcies)) %>%
    mutate(CS.exceeded = ifelse(`Credit Score`>1000, T,F)) %>%
    mutate(`Credit Score` = ifelse(`Credit Score` > 1000, `Credit Score`/10, `Credit Score`)) %>%
    mutate(Current.Loan.Amount.nan =ifelse(`Current Loan Amount`==99999999,T,F))%>%
    mutate(`Current Loan Amount` =ifelse(`Current Loan Amount`==99999999,NA,`Current Loan Amount`))%>%    
    mutate(Purpose = as.factor(stringr::str_to_lower(Purpose))) %>%
    mutate(`Home Ownership`=ifelse(`Home Ownership`=='HaveMortgage', 'Home Mortgage',`Home Ownership`)) %>%
    arrange(desc(`Loan ID`), desc(`Credit Score`)) %>%
    group_by(`Loan ID`) %>%
    filter(row_number()==1) %>%
    ungroup() %>%
    mutate(Income.Debt.Ratio= `Annual Income`/`Monthly Debt`)
```

ACC|AUC|tree tuning set |tree parameters ABCD| PL acc
---|---|-------|---|---
||| 20/10/0.2/200| ; without left_join; I cannot submit, wtf
||| 20/10/0.2/200| ; with left_join




todo:

* DONE home ownership: two categories can be merged

* DONE years in current job: conversion

* DONE: months since last delinquent: type conversion; contains many missing values

* DONE Tax liens: type conversion

* DONE bankruptcies: type conversion

* a prediction for each single row in the test data would make sense. one might have to join th epredictions on the original, uncleaned dataset (left join(original data, data, by = 'loan ID')

* feature selection: Reduce high (?) variance

## lgbc 17 

could not submit previous web service.

17 is a copy from lgbc 1

started out with a completely new script.
If this fails, I will have to dbug my R script step by step.

debugging with the test interface

switching to imputation with mean did help


ACC|AUC|tree tuning set |tree parameters ABCD| PL acc
---|---|-------|---|---
||| 20/10/0.2/200|failed: internal error, which has to do with the credit score column
|814|761| 20/10/0.2/200||70.2 ; back in business. Now continue with all previous steps. one at time. Next: check ACC AUC from this model.
|813|762| 20/10/0.2/200||step 1
|813|764||step 2
|782|792|| step 3: duplicate loan IDs fix: remember left_join!
|782|792|| step 4: distinct. no change, covered by previous step. really.
|776|792|| step 5; no improvement - dumped again. 
|793||804| step 6 : annual income/monthly debt ratio; ha we keep that one

off to lgbc 18 - I can't update teh 17 predictive model.

## lgbc 18

ACC|AUC|tree tuning set |tree parameters ABCD| PL acc
---|---|-------|---|---
783|793|| 20/10/0.2/200|71.377 + income debt ratio missing value filling;  still back in business. hoooray



I still need to implement the left join - I need kind of a fork node.
also, I am not using ln transformations. binnning for ratios (and additioanl ratios) would help, too.


## lgbc 19
ACC|AUC|tree tuning set |tree parameters ABCD| PL acc|
---|---|-------|---|---
748|746|20,10,0.2,100| | log transforms
737|740|20,10,0.2,200| |hm. back to 100
737|740|20,10,0.2,200| |hm. minimum leaves?
759|773|20,5,0.2,200| | filter selection: top 10 F WScore; numerical output from group bin thing
759|773|20,5,0.2,200| | filter selection: top 10 F WScore; numerical output from group bin thing;  left join also

competition entry failed with a complaint about missing features (leaving me clueless)

the error can also be observed in the web service test, even with sample data. Debugging requires a paid Azure acount, though.
left join drops accuracy to 0 (!!)

## lgbc 20

we try the same model once more. 
I have removed the 'feature selection step' from the predictive model. maybe that caused the issue...

ACC|AUC|tree tuning set |tree parameters ABCD| PL acc|comment|
---|---|-------|---|---|---
759|773|20,5,0.2,200| |71.88 | FS removed from predictive experiment. top, for now


## lgbc 20


ACC|AUC|tree tuning set |tree parameters ABCD| PL acc|comment|
---|---|-------|---|---|---
760|773|20,5,0.2,200| | | group bins removed
774|779||20,5,0.05,200||| lowered learning rate
774|779||20,5,0.01,200||| lowered learning rate. no effect, back to .05
771|778||20,5,0.05,200||| increased tree number. no effect, back to 200.

predictive experiment fails with some kind of infinty error. I recall vaguely, that this is why I introduced the group binning thingy.
somehow I need to exclude division by zero. simple solution: invert the ratios.



## lgbc 21

objectives: 
* to invert the ratios
* to insert a proper left join

ACC|AUC|tree tuning set |tree parameters ABCD| PL acc|comment|
---|---|-------|---|---|---
774| 779 |||start out|
772|779|||ratios inverted, annual income missing column added (appears to be important)|
772|779||| Max Open Credit converted to numeric, log, 
773|779|20 5 0.01 500|| Max Open Credit converted to numeric, log, 
776|784|||| Max Open Credit inf and nan replaced with na (realized only after sql transform)
776|784|20 5 0.01 500|| 72.60| Max Open Credit inf and nan replaced with na (realized only after sql transform)
YAY we have a winner, for now! PL # 54, two behind Rene Petz!

776|784|20 5 0.01 500|| *0* | lgbc 19, predictive + left join, left join fixed in R, worked fine in WS test; I give this path up...


my final cleaning code:
```
df1 <- maml.mapInputPort(1) # class: data.frame

print(names(df1))

library("dplyr")
library("magrittr")

#df2 <- select(df1, `Loan ID`)
df1 <- df1 %>%
    mutate(Current.Loan.Amount.exceeded = ifelse(`Current Loan Amount`==99999999, 
    T, F)) %>%
    mutate(`Current Loan Amount` = ifelse(`Current Loan Amount`==99999999, 
    NA, `Current Loan Amount`)) %>%
    mutate(Credit.Score.exceeded = ifelse(`Credit Score`>1000, 
    T, F)) %>%
    mutate(Annual.Income.missing = ifelse(is.na(`Annual Income`), T, F)) %>%
    mutate(`Credit Score` = as.numeric(ifelse(`Credit Score`>1000, 
    `Credit Score`/10, `Credit Score`))) %>%
    mutate(`Monthly Debt`= stringr::str_replace(`Monthly Debt`,"\\$","")) %>% #step 1
    mutate(`Monthly Debt`= as.numeric(`Monthly Debt`)) %>%
    mutate(Purpose = as.factor(stringr::str_to_lower(Purpose))) %>% #step 2
    mutate(`Home Ownership`=ifelse(`Home Ownership`=='HaveMortgage', 'Home Mortgage',`Home Ownership`)) %>%
    arrange(desc(`Loan ID`), desc(`Credit Score`)) %>% #step 3
    group_by(`Loan ID`) %>%#step 3
    filter(row_number()==1) %>%#step 3
    ungroup()%>%#step 3
    mutate(Debt.Income.Ratio= `Monthly Debt`/`Annual Income`) %>%
    mutate(Amount.Income.Ratio = `Current Loan Amount`/`Annual Income`) %>%
    mutate(`Annual Income`=log(`Annual Income`)) %>% # step 19-1
    mutate(`Current Loan Amount`=log(`Current Loan Amount`)) %>%
    mutate(`Maximum Open Credit`= log(as.numeric(`Maximum Open Credit`))) %>%
    mutate(`Maximum Open Credit` = ifelse(is.infinite(`Maximum Open Credit`), NA, `Maximum Open Credit`)) %>%
    mutate(`Maximum Open Credit` = ifelse(is.nan(`Maximum Open Credit`), NA, `Maximum Open Credit`)) %>%
    #mutate(`Current Credit Balance`= log(`Current Credit Balance`)) %>%
    #mutate(`Monthly Debt`= log(`Monthly Debt`))
    #mutate("Years in current job" = stringr::str_replace(`Years in current job`, 
    #' years*','')) %>%
    #mutate("Years in current job" = stringr::str_replace(`Years in current job`, 
    #'\\+',''))%>%
    #mutate("Years in current job" =  stringr::str_replace(`Years in current job`, 
    #'< 1','0')) %>%
    #mutate("Years in current job" = as.numeric(`Years in current job`))%>%
    mutate(Bankruptcies = as.numeric(Bankruptcies))

    
    
    # 
# for now, we exclude the wrongly coded credit scores.
# later, we divide those by 10
#df1 <- filter(df1, `Credit Score`< 1000)
maml.mapOutputPort("df1");

```
todo:

* sql left join
* tune the silly model


## lgbc 22

objectives: 
* to train using cross validation / tune hyper parameters
* to tune sensibly (follow e.g. https://www.analyticsvidhya.com/blog/2016/02/complete-guide-parameter-tuning-gradient-boosting-gbm-python/)

we cannot follow the tuning  guide directly, since we have only maximum number leaves per tree and minimum samples per leaf node.

the former encompasses probably max_depth

ACC|AUC|tree tuning set | PL acc|comment|
---|---|-------|---|---|---
784|796|20/50/0.1/40|| switched to 5 fold cross validation, tune hyperparameters, entire grid; 20/30/40/60/80
784|796|20/50/0.1/40|| max number of leaves, 5,10, 20, 40, 60, 80, 100; fine. next: decrease learning rate, increase # trees
783|796|20/200/0.1/40|| max number of leaves, 5,10, 20, 40, 60, 80, 100; fine. next: 
798|831|20/200/0.51/80|| max number of leaves, 5,10, 20, 40, 60, 80, 100; silly large LR. One more, maybe?
784|796|20/200/0.05/80|| max number of leaves, 5,10, 20, 40, 60, 80, 100; hm. More trees!
783|795|20/200/0.02/160|| max number of leaves, 5,10, 20, 40, 60, 80, 100; hm. More trees!
785|801|20/200/0.02/320|72.57| max number of leaves, 5,10, 20, 40, 60, 80, 100; hm. Time for submission, to prevent overfitting.

## lgbc 23

objective:

* to evaluate bayes point machines
* to evaluate stacking/averaging

ACC|AUC|tree tuning set | PL acc|comment|
---|---|-------|---|---|---
773|768|||30 training iterations
774|771|||90 training iterations

we give up on stacking, for now. 

## lgbc 24

objective:

* to deal with imbalance, otherwise like 22

ACC|AUC|tree tuning set | PL acc|comment|
---|---|-------|---|---|---
719|801|20/200/0.02/320||smote, 100%, on the feature-selected data
732|822|40/200/0.02/320||smote, 100%, on the feature-selected data
741|832|60/200/0.02/320|| see above
748|839|70/100/0.02/320|68 something| overfitting? Time for a submission.

Apparently, smote does work fine on the training data, but is of little use for the silly test data.

## lgbc 25

ACC|AUC|tree tuning set | PL acc|comment|
---|---|-------|---|---|---
788|807|30/100/0.02/320||
788|807|30/100/0.02/320|| log(debt.amount.ratio), cleaned
788|807|30/100/0.02/320|| no change. extend feature selection
788|809|30/100/0.02/320|| impute with median!
788|809|30/100/0.02/320|72.6881| submission...

## lgbc 26

790|810|30/100/0.02/320|72.6881| more features used

* to engineer the ratio features
* smote does not help: discard
## lgbc 27

with loan ID


ACC|AUC|tree tuning set | PL acc|comment|
---|---|-------|---|---|---
831|888|30/100/0.02/320|72.6881| lid4, binned in two groups # lots of missings
792|815|| lid 2,3,4, na filled with median, 19 features
