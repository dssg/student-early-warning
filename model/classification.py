"""
Classification Pipeline
"""

#########################################################################################
#        Data Science for Social Good Fellowship 2014 (http://dssg.uchicago.edu)        #
# Identifying students at risk accurately and early -- Montgomery County Public Schools #
#                                                                                       #
# Team Members: Everaldo Aguiar, Nasir Bhanpuri, Himabindu Lakkaraju, David Miller      #
# Team Mentor: Ben Yuhas                                                                #
#                                                                                       #
# This code encapsulates a supervised learning pipeline that allows a user to input a   #
# pandas DataFrame, select a dependent variable and quickly perform classification      #
# using a variety of models while displaying the results several different ways.        #
#                                                                                       #
#                                    Version 1.0                                        #
#########################################################################################

from sklearn import preprocessing, decomposition, svm, cross_validation
from sklearn.tree import DecisionTreeClassifier
from sklearn.ensemble import RandomForestClassifier, ExtraTreesClassifier, GradientBoostingClassifier, AdaBoostClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.naive_bayes import GaussianNB
from sklearn.neighbors import NearestNeighbors
from sklearn.metrics import *
import random
import numpy as np
import matplotlib.pylab as pl



#####################################################################################
# List all classifiers and their initialization parameters in the dictionary below: # 
# The runClassification function will accept a list with the classifiers that the   #
# user wishes to run.                                                               #
#####################################################################################

clfs = {'RF': RandomForestClassifier(n_estimators=50, n_jobs=-1),
        'ET': ExtraTreesClassifier(n_estimators=10, n_jobs=-1, criterion='entropy'),
        'AB': AdaBoostClassifier(DecisionTreeClassifier(max_depth=1), algorithm="SAMME", n_estimators=200),
        'LR': LogisticRegression(penalty='l1', C=1e5),
        'SVM': svm.SVC(kernel='linear', probability=True, random_state=0),
        'GB': GradientBoostingClassifier(learning_rate=0.05, subsample=0.5, max_depth=6, n_estimators=10),
        'NB': GaussianNB(),
        'DT': DecisionTreeClassifier()
        }


class Model:

    def __init__(self, dataSet, dependentVar, doFeatureSelection=True, doPCA=False, nComponents=10):
        """ Data pre-processing constructor.

        Constructor to pre-process pandas DataFrames, extracting and encoding the outcome
        labels (class), dropping them from the dataset and converting categorical variables
        into integer numbers for compatibility with scikit-learn.

        Parameters
        ----------
        dataSet : pd.DataFrame
            The entire dataset as loaded and parsed in the main program
        dependentVar : string
            A string denoting the column to be used as the class
        doFeatureSelection : bool
            A flag to denote whether or not to perform feature selection
        doPCA : bool
            A flag to denote whether or not to perform principle component analysis
        nComponents : int
            The desired number of principle components
        
        """
        # Encode nominal features to conform with sklearn
        for i,tp in enumerate(dataSet.dtypes):
            if tp == 'object': 
                unique_vals, dataSet.ix[:,i]  = np.unique(dataSet.ix[:,i] , return_inverse=True)
                
        # Set the dependent variable (y) to the appropriate column
        y = dataSet.loc[:,dependentVar]

        # Transform that information to a format that scikit-learn understands
        # This may be redundant at times
        labels = preprocessing.LabelEncoder().fit_transform(y)

        # Remove the dependent variable from training sets
        X = dataSet.drop(dependentVar,1).values
        
        # Perform entropy-based feature selection 
        if doFeatureSelection:
            print 'Performing Feature Selection:'
            print 'Shape of dataset before feature selection: ' + str(X.shape)
            clf = DecisionTreeClassifier(criterion='entropy')
            X = clf.fit(X, y).transform(X)
            print 'Shape of dataset after feature selection: ' + str(X.shape) + '\n'
        
        # Normalize values
        X = preprocessing.StandardScaler().fit(X).transform(X)
        
        # Collapse features using principal component analysis
        if doPCA:
            print 'Performing PCA'
            estimator = decomposition.PCA(n_components=nComponents)
            X = estimator.fit_transform(X)
            print 'Shape of dataset after PCA: ' + str(X.shape) + '\n'
            
        # Save processed dataset, labels and student ids
        self.dataset = X
        self.labels = labels
        self.students = dataSet.index


    def subsample(self, x, y, ix, subsample_ratio=1.0):
        """ Data subsampling.
        
        This function takes in a list or array indexes that will be used for training
        and it performs subsampling in the majority class (c == 0) to enforce a certain ratio
        between the two classes

        Parameters
        ----------
        x : np.ndarray
            The entire dataset as a ndarray
        y : np.ndarray
            The labels
        ix : np.ndarray
            The array indexes for the instances that will be used for training
        subsample_ratio : float
            The desired ratio for subsampling
        
        Returns
        --------
        np.ndarray 
            The new list of array indexes to be used for training
        """

        # Get indexes of instances that belong to classes 0 and 1
        indexes_0 = [item for item in ix if y[item] == 0]
        indexes_1 = [item for item in ix if y[item] == 1]

        # Determine how large the new majority class set should be
        sample_length = int(len(indexes_1)*subsample_ratio)
        sample_indexes = random.sample(indexes_0, sample_length) + indexes_1

        return sample_indexes


    #############################################################
    # SMOTE implementation by Karsten Jeschkies                 #
    # The MIT License (MIT)                                     #
    # Copyright (c) 2012-2013 Karsten Jeschkies <jeskar@web.de> # 
    #                                                           #
    # This is an implementation of the SMOTE Algorithm.         #
    # See: "SMOTE: synthetic minority over-sampling technique"  #
    # by Chawla, N.V et al.                                     #
    #############################################################

    def SMOTE(self, T, N, k, h = 1.0):
        """ Synthetic minority oversampling.

        Returns (N/100) * n_minority_samples synthetic minority samples.

        Parameters
        ----------
        T : array-like, shape = [n_minority_samples, n_features]
            Holds the minority samples
        N : percetange of new synthetic samples: 
            n_synthetic_samples = N/100 * n_minority_samples. Can be < 100.
        k : int. Number of nearest neighbours. 

        Returns
        -------
        S : Synthetic samples. array, 
            shape = [(N/100) * n_minority_samples, n_features]. 
        """    
        n_minority_samples, n_features = T.shape
        
        if N < 100:
            #create synthetic samples only for a subset of T.
            #TODO: select random minortiy samples
            N = 100
            pass

        if (N % 100) != 0:
            raise ValueError("N must be < 100 or multiple of 100")
        
        N = N/100
        n_synthetic_samples = N * n_minority_samples
        S = np.zeros(shape=(n_synthetic_samples, n_features))
        
        #Learn nearest neighbours
        neigh = NearestNeighbors(n_neighbors = k)
        neigh.fit(T)
        
        #Calculate synthetic samples
        for i in xrange(n_minority_samples):
            nn = neigh.kneighbors(T[i], return_distance=False)
            for n in xrange(N):
                nn_index = random.choice(nn[0])
                #NOTE: nn includes T[i], we don't want to select it 
                while nn_index == i:
                    nn_index = random.choice(nn[0])
                    
                dif = T[nn_index] - T[i]
                gap = np.random.uniform(low = 0.0, high = h)
                S[n + i * N, :] = T[i,:] + gap * dif[:]
        
        return S


    def runClassification(self, outputFormat='score', doSubsampling=False, subRate=1.0,
                            doSMOTE=False, pctSMOTE=100, nFolds=10, models=['LR'], topK=.1):
        """ Main function to train and evaluate model

        Allows user to set the type of output and a few other parameters to running a K-fold
        cross validation experiment.        

        Parameters
        ----------
        outputFormat :  string
            The desired output format. Choices are: 'score', 'summary', 'matrix', 'roc', 'prc', 'topk' and 'risk'
        doSubsampling : bool
            Boolean value to determine wether to subsample de majority class
        subRate : float
            The ratio majority/minority to keep for training
        doSMOTE : bool
            Boolean value to determine whether or not to run SMOTE on the training set
        pctSMOTE : int
            The oversampling percentage to be used by SMOTE
        nFolds : int
            The number of folds to be assigned to the K-fold process    
        models : list
            A list of classifiers to evaluate given by the 2-3 letter codes above
        
        Returns
        --------
            Results are displayed inline for now
            
        """

        # Return a simple overall accuracy score
        if outputFormat=='score':
            if doSMOTE or doSubsampling:
                print 'Sorry, scoring with subsampling or SMOTE not yet implemented'
                return
            # Iterate through each classifier to be evaluated
            for ix,clf in enumerate([clfs[x] for x in models]):
                kf = cross_validation.KFold(len(self.dataset), nFolds, shuffle=True)
                scores = cross_validation.cross_val_score(clf, self.dataset, self.labels, cv=kf)
                print models[ix]+ ' Accuracy: %.2f' % np.mean(scores)
        
        # Return a summary table describing several metrics or a confusion matrix 
        elif outputFormat=='summary' or outputFormat=='matrix':
            for ix,clf in enumerate([clfs[x] for x in models]):
                # Store the prediction results and their corresponding real labels for each fold
                y_prediction_results = []; y_smote_prediction_results = []
                y_oringinal_values = []
                
                # Generate indexes for the K-fold setup
                kf = cross_validation.StratifiedKFold(self.labels, n_folds=nFolds)
                for i, (train, test) in enumerate(kf):
                    if doSubsampling:
                    	# Remove some random majority class instances to balance data
                        train = self.subsample(self.dataset,self.labels,train,subRate)
                    if doSMOTE:
                        # SMOTE the minority class and append new instances to training set 
                        minority = self.dataset[train][np.where(self.labels[train]==1)]
                        smotted = self.SMOTE(minority, pctSMOTE, 5)
                        X_train_smote = np.vstack((self.dataset[train],smotted))
                        y_train_smote = np.append(self.labels[train],np.ones(len(smotted),dtype=np.int32))
                        # Fit the new training set to selected model
                        y_pred_smote = clf.fit(X_train_smote, y_train_smote).predict(self.dataset[test])
                        # Generate SMOTEd predictions and append that to the rersults list 
                        y_smote_prediction_results = np.concatenate((y_smote_prediction_results,y_pred_smote),axis=0)
                        
                    # Generate predictions for current hold-out sample in i-th fold
                    y_pred = clf.fit(self.dataset[train], self.labels[train]).predict(self.dataset[test])
                    # Append results to previous ones
                    y_prediction_results = np.concatenate((y_prediction_results,y_pred),axis=0)
                    # Store the corresponding original values for the predictions just generated
                    y_oringinal_values = np.concatenate((y_oringinal_values,self.labels[test]),axis=0)
                
                # Print result summary table based on k-fold 
                # This is specific to our particular experiment and classes are hard coded
                # When oversampling is True, both results are displayed
                if outputFormat=='summary':
                    print '\t\t\t\t\t\t'+models[ix]+ ' Summary Results'
                    cm = classification_report(y_oringinal_values, y_prediction_results,target_names=['Graduated','Did NOT Graduate'])
                    print(str(cm)+'\n')
                    if doSMOTE:
                        print '\t\t\t\t\t\t'+models[ix]+ ' SMOTE Summary Results'
                        cm = classification_report(y_oringinal_values, y_smote_prediction_results,target_names=['Graduated','Did NOT Graduate'])
                        print(str(cm)+'\n')
                    print '----------------------------------------------------------\n'
                
                # Print the confusion matrix
                else:
                    print '\t\t\t\t\t'+models[ix]+ ' Confusion Matrix'
                    print '\t\t\t\tGraduated\tDid NOT Graduate'
                    cm = confusion_matrix(y_oringinal_values, y_prediction_results)
                    print 'Graduated\t\t\t%d\t\t%d'% (cm[0][0],cm[0][1])
                    print 'Did NOT Graduate\t%d\t\t%d'% (cm[1][0],cm[1][1])
                    if doSMOTE:
                        print '\n\t\t\t\t'+models[ix]+ ' SMOTE Confusion Matrix'
                        print '\t\t\t\tGraduated\tDid NOT Graduate'
                        cm = confusion_matrix(y_oringinal_values, y_smote_prediction_results)
                        print 'Graduated\t\t\t%d\t\t%d'% (cm[0][0],cm[0][1])
                        print 'Did NOT Graduate\t%d\t\t%d'% (cm[1][0],cm[1][1])
                        
                    print '----------------------------------------------------------\n'
                
        # Generate ROC curves 
        # The majority of the structure here is similar to above, so refer to early comments
        # TO DO: create consise procedures to avoid code duplication
        elif outputFormat=='roc':
            for ix,clf in enumerate([clfs[x] for x in models]):
                kf = cross_validation.StratifiedKFold(self.labels, n_folds=nFolds)
                mean_tpr = mean_smote_tpr = 0.0
                mean_fpr = mean_smote_fpr = np.linspace(0, 1, 100)
                
                for i, (train, test) in enumerate(kf):
                    if doSubsampling:
                        train = self.subsample(self.dataset,self.labels,train,subRate)
                    if doSMOTE:
                        minority = self.dataset[train][np.where(self.labels[train]==1)]
                        smotted = self.SMOTE(minority, pctSMOTE, 5)
                        X_train = np.vstack((self.dataset[train],smotted))
                        y_train = np.append(self.labels[train],np.ones(len(smotted),dtype=np.int32))
                        probas2_ = clf.fit(X_train, y_train).predict_proba(self.dataset[test])
                        fpr, tpr, thresholds = roc_curve(self.labels[test], probas2_[:, 1])
                        mean_smote_tpr += np.interp(mean_smote_fpr, fpr, tpr)
                        mean_smote_tpr[0] = 0.0

                    # Generate "probabilities" for the current hold out sample being predicted
                    probas_ = clf.fit(self.dataset[train], self.labels[train]).predict_proba(self.dataset[test])
                    # Compute ROC curve and area the curve
                    fpr, tpr, thresholds = roc_curve(self.labels[test], probas_[:, 1])
                    mean_tpr += np.interp(mean_fpr, fpr, tpr)

                # Plot ROC baseline
                pl.plot([0, 1], [0, 1], '--', color=(0.6, 0.6, 0.6), label='Baseline')

                # Compute true positive rates
                mean_tpr /= len(kf)
                mean_tpr[-1] = 1.0
                mean_auc = auc(mean_fpr, mean_tpr)

                # Plot results
                pl.plot(mean_fpr, mean_tpr, 'k-',
                        label='Mean ROC (area = %0.2f)' % mean_auc, lw=2)
                        
                # Plot results with oversampling
                if doSMOTE:
                    mean_smote_tpr /= len(kf)
                    mean_smote_tpr[-1] = 1.0
                    mean_smote_auc = auc(mean_smote_fpr, mean_smote_tpr)
                    pl.plot(mean_smote_fpr, mean_smote_tpr, 'r-',
                        label='Mean smote ROC (area = %0.2f)' % mean_smote_auc, lw=2)

                pl.xlim([-0.05, 1.05])
                pl.ylim([-0.05, 1.05])
                pl.xlabel('False Positive Rate')
                pl.ylabel('True Positive Rate')
                pl.title(models[ix]+ ' ROC')
                pl.legend(loc="lower right")
                pl.show()
                
        # Generate Precision-Recall curves, topK precision, or list of topK at risk scores
        elif outputFormat =='prc' or outputFormat =='topk' or outputFormat =='risk':
            for ix,clf in enumerate([clfs[x] for x in models]):
                y_prob = []; y_smote_prob = []
                y_prediction_results = []; y_smote_prediction_results = []
                y_oringinal_values = []; test_indexes = []
            
                kf = cross_validation.StratifiedKFold(self.labels, n_folds=nFolds, shuffle=True)
                mean_pr = mean_smote_pr = 0.0
                mean_rc = mean_smote_rc = np.linspace(0, 1, 100)
                
                for i, (train, test) in enumerate(kf):
                    if doSubsampling:
                        train = self.subsample(self.dataset,self.labels,train,subRate)
                        
                    if doSMOTE:
                        clf2 = clf
                        minority = self.dataset[train][np.where(self.labels[train]==1)]
                        smotted = self.SMOTE(minority, pctSMOTE, 5)
                        X_train = np.vstack((self.dataset[train],smotted))
                        y_train = np.append(self.labels[train],np.ones(len(smotted),dtype=np.int32))
                        clf2.fit(X_train, y_train)
                        probas2_ = clf2.predict_proba(self.dataset[test])
                        y_pred_smote = clf2.predict(self.dataset[test])
                        # Generate SMOTEd predictions and append that to the rersults list 
                        y_smote_prediction_results = np.concatenate((y_smote_prediction_results,y_pred_smote),axis=0)
                        y_smote_prob = np.concatenate((y_smote_prob,probas2_[:, 1]),axis=0)

                    clf.fit(self.dataset[train], self.labels[train])
                    y_pred = clf.predict(self.dataset[test])
                    y_prediction_results = np.concatenate((y_prediction_results,y_pred),axis=0)
                    test_indexes = np.concatenate((test_indexes,test),axis=0)
                    y_oringinal_values = np.concatenate((y_oringinal_values,self.labels[test]),axis=0)
                    probas_ = clf.predict_proba(self.dataset[test])
                    y_prob = np.concatenate((y_prob,probas_[:, 1]),axis=0)
                    
                # Compute overall prediction, recall and area under PR-curve
                precision, recall, thresholds = precision_recall_curve(y_oringinal_values, y_prob)
                pr_auc = auc(recall, precision)
                
                        
                if doSMOTE:
                    precision_smote, recall_smote, thresholds_smote = precision_recall_curve(y_oringinal_values, y_smote_prob)
                    pr_auc_smote = auc(recall_smote, precision_smote)

                # Output the precision recall curve
                if outputFormat=='prc':
                    pl.plot(recall, precision, color = 'b', label='Precision-Recall curve (area = %0.2f)' % pr_auc)
                    if doSMOTE:
                        pl.plot(recall_smote, precision_smote, color = 'r', label='SMOTE Precision-Recall curve (area = %0.2f)' % pr_auc_smote)
                    pl.xlim([-0.05, 1.05])
                    pl.ylim([-0.05, 1.05])
                    pl.xlabel('Recall')
                    pl.ylabel('Precision')
                    pl.title(models[ix]+ ' Precision-Recall')
                    pl.legend(loc="lower right")
                    pl.show()
                    
                # Output a list of the topK% students at highest risk along with their risk scores
                elif outputFormat =='risk':
                    sort_ix = np.argsort(test_indexes)
                    students_by_risk = self.students[sort_ix]
                    y_prob = ((y_prob[sort_ix])*100).astype(int)
                    probas = np.column_stack((students_by_risk,y_prob))
                    r = int(topK*len(y_oringinal_values))
                    print models[ix]+ ' top ' + str(100*topK) + '%' + ' highest risk'
                    print '--------------------------'
                    print '%-15s %-10s' % ('Student','Risk Score')
                    print '%-15s %-10s' % ('-------','----------')
                    probas = probas[np.argsort(probas[:, 1])[::-1]]
                    for i in range(r):
                        print '%-15s %-10d' % (probas[i][0], probas[i][1])
                    print '\n'
                
                # Output the precision on the topK%   
                else:
                    ord_prob = np.argsort(y_prob,)[::-1] 
                    r = int(topK*len(y_oringinal_values))
                    print models[ix]+ ' Precision at top ' + str(100*topK) + '%'
                    print np.sum(y_oringinal_values[ord_prob][:r])/r

                    if doSMOTE:
                        ord_prob = np.argsort(y_smote_prob,)[::-1] 
                        print models[ix]+ ' SMOTE Precision at top ' + str(100*topK) + '%'
                        print np.sum(y_oringinal_values[ord_prob][:r])/r
                    print '\n'