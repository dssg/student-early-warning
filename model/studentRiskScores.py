import classification
import pandas as pd

# Load simulated data set for experiment
df = pd.read_csv('../data/simulated_data.csv',index_col=0)

# Create a model object using the loaded data
pred = classification.Model(df,'nograd',doFeatureSelection=True)

# Run classification using 10-fold cross validation
# Classifier used: Logistic Regression (LR)
# Output format:List of risk scores for the top 5% of students at highest risk
pred.runClassification(outputFormat='risk', models=['RF'], topK=.05, nFolds=10)