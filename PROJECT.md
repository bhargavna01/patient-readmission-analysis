# Project: Patient Readmission Analysis

## Overview
Hospital readmissions are a major focus for healthcare systems because they are costly and often serve as an indicator of the quality of patient care. This project aims to analyze historical patient clinical records to identify key drivers of readmissions (specifically within 30 days of discharge) and build a predictive model to identify high-risk patients.

## Data Source & Database Hosting
- **Data Source**: [UCI Diabetes 130-US Hospitals (1999-2008) Dataset](https://archive.ics.uci.edu/dataset/296/diabetes+130-us+hospitals+for+years+1999-2008)
- **Database Hosting**: [Neon Serverless PostgreSQL Branch](https://console.neon.tech/app/projects/cold-brook-55376009/branches/br-flat-glade-ayhi7hms/)

## Methodology: Polars vs. PostgreSQL (PSQL) Benchmarking
To test coding proficiency and evaluate execution efficiency, all data cleaning, profiling, and transformation tasks will be performed side-by-side using two parallel approaches:
1. **Polars**: A highly optimized, multi-threaded DataFrame library in Python built on the Apache Arrow memory model.
2. **PostgreSQL (PSQL)**: A robust relational database management system hosted on Neon serverless PostgreSQL.

This dual pipeline allows us to benchmark:
- Development speed and syntax readability (SQL vs. Polars Expression API).
- Execution efficiency (in-memory processing vs. relational database query planner).

## Objectives
1. **Explore & Profile**: Analyze patient demographics, primary diagnoses, admission types, and lengths of stay to understand their correlation with readmission.
2. **Predictive Modeling**: Train a machine learning classifier to predict the probability of a patient being readmitted within 30 days.
3. **Actionable Insights**: Provide clinicians and hospital administrators with key factors that contribute to readmissions (e.g., specific diagnoses, number of prior visits) to help design targeted intervention programs.

## Key Metrics
- **30-Day Readmission Rate**: The percentage of hospital admissions that result in a readmission within 30 days of discharge.
- **Model Performance**:
  - ROC-AUC (Primary classification metric)
  - Recall/Sensitivity (To minimize false negatives and identify as many high-risk patients as possible)
  - Precision/Positive Predictive Value (To target resources effectively)

### Project Documentation
Detailed specifications, schemas, and reports are available in the following files:
- **[Data Dictionary](docs/data_dictionary.md)**: Full details on all 50 attributes, datatypes, and descriptions.
- **[Data Quality & Profiling Report](docs/data_quality_report.md)**: Statistics on missing values, duplicate encounters, and data sanity checks.
- **[Methodology & Benchmarking](docs/methodology.md)**: A comparison of the parallel Polars vs. PostgreSQL pipelines.

## Analysis Workflow
1. **SQL Staging & Extraction**: Standardize raw EHR data, handle null keys, and load into a structured table.
2. **SQL Profiling**: Perform initial statistical profiling (value counts, ranges, missingness analysis) inside the database.
3. **SQL Transformation**: Build clean views that encode categorical variables, bin ages, group ICD-9 codes (e.g., Circulatory, Respiratory, Digestive, Diabetes), and format final fields.
4. **Notebook Exploratory Analysis (EDA)**: Load clean data into Python, generate demographic distribution charts, and analyze readmission rates across features.
5. **Machine Learning Model**: Train classification models (Logistic Regression, Random Forest, or XGBoost), evaluate feature importances, and plot ROC/PR curves.
