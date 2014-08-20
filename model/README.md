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
