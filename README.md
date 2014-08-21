#Identifying students at risk accurately and early

<a href="http://www.montgomeryschoolsmd.org/"><img src="http://dssg.uchicago.edu/img/partners/mcps.png" width="300" align="right"></a>

Based on a variety of longitudinal, student-level data, we developed predictive models to identify students who are at risk of not graduating high school on time and may benefit from targeted interventions.

This is a 2014 [Data Science for Social Good](http://www.dssg.io) project in partnership with the [Montgomery County Public School System](http://www.montgomeryschoolsmd.org/).

## The problems: on-time graduation and college undermatching

To ensure that all students are on track for success, Montgomery County Public Schools (MCPS) in Rockville, Maryland built their own “early warning” model to identify students who may need extra attention.  MCPS keeps track of grades, attendance, and other measures from as early as 6th grade.

Our team's goals included a comprehensive validation and enhancement of our partner's model, using new sources of student-level data and applying additional machine learning approaches to improve predictive power. In this particular setting, we attempted to predict students that were unlikely to graduate on time and which ones were more urgently in need of attention. A student _did not_ graduate on time when:
* the student dropped out of school sometime after enrollment, or
* the student was retained (i.e. needed to repeat a grade), and spent more than four years in high school

Further, even when students perform at their full potential, lack of information and guidance can often cause some to end up _undermatching_, that is, applying to post-secondary institutions below their capability or not applying at all. By merging secondary and post-secondary longitudinal student datasets, we delivered a detailed exploratory analysis illustrating which subgroups of students were prone to this particular issue. 



## The solution: prediction and targeting

Our major goal was to identify students who are at risk for not graduating on time. We used data from previous high school cohorts and modeled their outcomes. We can then apply this predictive model on current students to predict their risk of falling behind. As a second step, we applied survival analysis techniques to generate an *urgency* score associated with each of the students. This additional information can be used by school counselors to decide which students are in most immediate need of attention.

To explore possible undermatching, we merged student data from the final year of high school with 5 years of post-secondary enrollment and graduation data. We used a combination of clustering techniques to compare students with similar acadmic and behavioral data but different demographics to identify student groups that were undermatching relative to their peers.


## The data

For the initial portion of this project, we were given a dataset containing anonymized records of one cohort of students tracked from the beginning of sixth grade and throughout their high school years. Each academic year in the dataset contained a variety of features that can be largely grouped into three categories: academic (e.g., quarterly gpas, standardized test scores), behavioral (e.g., percentage of time absent, number of suspensions, tardiness rate) and enrollment-related (e.g., mobility, new to school district, new to the US). We were also given flags that denoted each time a student fell behind and had to repeat a grade.

Read more about the data we used in the wiki (add link to **data** wiki page here)

## The deliverables

The main goals of this project were to both: (i) generate accurate predictions and (ii) present the predictions through an actionable interface. Thus, a large amount of our efforts went into the design and implementation of a web-based tool that can be used by school administrators and counselors to track the *risk scores* of their students over time, allowing them to easily identify students that are in need of personal attention. 

A live demo of our risk score dashboard can be accessed [**here**](http://d-miller.shinyapps.io/RiskVizDemo/).

###Early warning dashboard and student "report card"

Using previously tuned predictive models, we can generate risk scores for new sets of students. These scores illustrate how likely/unlikely each student is to graduate on time, but they provide little insight as to the reasons why a student might be *at risk*. To address this issue, our web interface provides a risk score and a breakdown of a few other important features, color-coded to show how "far" a student is from the median observed across the entire population. This gives educators the opportunity to not only identify the students who are at risk, but it also provides some insight as to how students differ and what may be underlying a given student's problem--allowing for better informed and personalized interventions. 

![Dashboard](http://i.imgur.com/050QiW1.png)

## Project layout

This repository is organized into four directories: `model`, `survival`, `dashboard` and `undermatch` containing code responsible for:
* `model`: training and evaluating classification models to predict student graduation 
* `survival`: generating urgency scores for those students labeled as being at risk
* `dashboard`: creating the interactive student dashboard described above
* `undermath`: performing some exploratory to identify groups that may be undermatching respectively.

## Using our code
Starting with the simulated dataset (or one of your own that adheres to that format) contained in `./data/`, you can train our models to predict the **the likelihood of not graduating on time** for a list of students and evaluate each model using a wide range of metrics.

To do so, run the following commands:

```
python model/classification.py
R CMD BATCH add-R-stuff-here
```

Please refer to the the content of each subfolder for a brief description of the required dependencies and further instructions.


## Team
![Team](http://i.imgur.com/xnpv0u7.png)
