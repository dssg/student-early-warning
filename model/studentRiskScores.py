import classification
import pandas as pd

# Load simulated data set for experiment
df = pd.read_csv('../data/simulated_data.csv',index_col=0)

# Create a model object using the loaded data
pred = classification.Model(df,'nograd',doFeatureSelection=False)

# Run classification using 10-fold cross validation, logistic regression, and reporting risk scores for the top 5% of students at highest risk
pred.runClassification(outputFormat='risk', models=['LR'], topK=.05, nFolds=10)