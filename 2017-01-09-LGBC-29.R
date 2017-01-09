# LGBC 29
# Accuracy .820
# AUC .840
# obtained with 3-fold CV

# PL score 72.97601

# Execute R script module
# followed by grouping years in current job in 4 bins

# Missing values median-filled:
# Current Loan Amount, Credit Score, Annual Income, Monthly Debt, 
# Ratios, Maximum Open Credit, Current Credit Balance 

# Missing values zero-filled:
# Current.Loan.Amount.exceeded, Credit.Score.exceeded, Tax Liens

# Running with MRO 3.2.2
df1 <- maml.mapInputPort(1) # class: data.frame

library("dplyr")
library("magrittr")
library("tidyr")
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
  filter(!is.na(`Credit Score`)) %>%
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
  
  mutate(Debt.Amount.Ratio = log(`Monthly Debt`/`Current Loan Amount`))%>%
  mutate(Debt.Amount.Ratio = ifelse(is.infinite(Debt.Amount.Ratio), NA, Debt.Amount.Ratio)) %>%
  mutate(Debt.Amount.Ratio = ifelse(is.nan(Debt.Amount.Ratio), NA, Debt.Amount.Ratio)) %>%
  
  mutate(`Annual Income`=log(`Annual Income`)) %>% # step 19-1
  mutate(`Current Loan Amount`=log(`Current Loan Amount`)) %>%
  mutate(`Maximum Open Credit`= log(as.numeric(`Maximum Open Credit`))) %>%
  mutate(`Maximum Open Credit` = ifelse(is.infinite(`Maximum Open Credit`), NA, `Maximum Open Credit`)) %>%
  mutate(`Maximum Open Credit` = ifelse(is.nan(`Maximum Open Credit`), NA, `Maximum Open Credit`)) %>%
  mutate(`Current Credit Balance`= log(`Current Credit Balance`)) %>%
  mutate( `Current Credit Balance`= ifelse(is.infinite(`Current Credit Balance`), NA, `Current Credit Balance`)) %>%
  mutate(`Current Credit Balance` = ifelse(is.nan(`Current Credit Balance`), NA, `Current Credit Balance`)) %>%
  #mutate(`Monthly Debt`= log(`Monthly Debt`))
  mutate("Years in current job" = stringr::str_replace(`Years in current job`, 
                                                       ' years*','')) %>%
  mutate("Years in current job" = stringr::str_replace(`Years in current job`, 
                                                       '\\+',''))%>%
  mutate("Years in current job" =  stringr::str_replace(`Years in current job`, 
                                                        '< 1','0')) %>%
  mutate("Years in current job" = as.numeric(`Years in current job`))%>%
  mutate(Bankruptcies = as.numeric(Bankruptcies)) %>%
  mutate(`Tax Liens` = as.numeric(`Tax Liens`))


maml.mapOutputPort("df1");
