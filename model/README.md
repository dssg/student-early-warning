## Running the Python student risk score code

Below we highlight the code dependencies as well as a complete list of all available functionality.

### Dependencies

The following must be installed prior to running the code. Newer versions may become available and will likely be backwards compatible, but we list the exact versions that have been tested with our code.

* Python 2.7.6
* pandas 0.14.1
* scikit-learn 0.15.1
* numpy 1.8.1
* matplotlib 1.3.1


### Running the script

The code in `studentRiskScores.py` uses a class defined in `classification.py` to create an object based on our simulated student dataset, and it creates a classification model that attempts to predict if a student is likely to graduate on time, displaying results in a variety of ways.

The code below loads the simulated student dataset as a pandas DataFrame and creates a `Model` object that will be used to perform predictions:

```python
import classification
import pandas as pd

# Load simulated data set for experiment
df = pd.read_csv('../data/simulated_data.csv',index_col=0)

# Create a model object using the loaded data
pred = classification.Model(df,'nograd')
```

###### Displaying a list with students at highest risk along with their risk scores

```python
# Returns the top 5% of students at highest risk
# based on the output of a RandomForest model using 10-fold cross validation
pred.runClassification(outputFormat='risk', models=['RF'], topK=.05, nFolds=10)
```

Above, the parameter *outputFormat* can take the following values: `'score'`, `'summary'`, `'matrix'`, `'roc'`, `'prc'`, `'topk'` or `'risk'`,  all of which produce a different kind of output. Please refer to the comments in `classification.py` for a more detailed explanation of each. Below is an example of how to display the result as an ROC curve while also performing oversampling to improve performance.

```python
pred.runClassification(outputFormat='roc', models=['SVM'], doSMOTE=True, pctSMOTE=200, nFolds=10)
```

*Output:*

![roc](http://i.imgur.com/HN3Nzei.png)
