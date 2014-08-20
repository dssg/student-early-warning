import classification
import pandas as pd

df = pd.read_csv('../data/simulated_data.csv',index_col=0)

pred = classification.Model(df,'nograd',doFeatureSelection=False)

pred.runClassification(outputFormat='risk', doSubsampling=False, doSMOTE=True, pctSMOTE=200, models=['LR','RF'],topK=.05,nFolds=10)