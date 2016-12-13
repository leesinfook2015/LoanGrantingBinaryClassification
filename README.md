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

This very simple initial model took me on place 12 in the public leaderboard with an accurac of 68.673% (admittedly, there were only 28 submissions at the time of entry). However, and more importantly, this simple model provides a fully functional base on which I can perform subsequent feature engineering, model tuning and general improvements of prediction.

# LGBCD 1-missing-values-fixed
After an exploratory data analysis (to be posted separately), I iterated the initial two-class boosted decision tree model experiment. Briefly, I inserted an 'Execute R script' module, which replaced Current Loan Amount values of 99999999 with NAs. In the following clean-missing-data module, the such flagged values were imputed using MICE with five iterations - just as Credit score and Annual income.

In a further preprocessing step, we should deal with the Credit Score issue.




Accuracy on test set: 70.893508, PL 36/144
