# Project: Patient Readmission Analysis

## Overview
Hospital readmissions are a major focus for healthcare systems because they are costly and often serve as an indicator of the quality of patient care. This project aims to analyze historical patient clinical records to identify key drivers of readmissions (specifically within 30 days of discharge) and build a predictive model to identify high-risk patients.

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

## Data Dictionary (Target Schema)
We assume a clinical database containing the following core attributes:

| Column Name | Data Type | Description |
|---|---|---|
| `encounter_id` | INTEGER | Unique identifier for the hospital encounter/admission |
| `patient_id` | INTEGER | Unique identifier for the patient |
| `age` | VARCHAR / INTEGER | Age or age group of the patient |
| `gender` | VARCHAR | Gender of the patient (Male, Female, etc.) |
| `admission_type` | VARCHAR | Emergency, Urgent, Elective, Newborn, etc. |
| `length_of_stay` | INTEGER | Total days spent in the hospital during the encounter |
| `primary_diagnosis_code` | VARCHAR | ICD-9 or ICD-10 code for the primary diagnosis |
| `num_lab_procedures` | INTEGER | Number of lab tests performed during the encounter |
| `num_medications` | INTEGER | Number of unique medications prescribed |
| `number_emergency_visits` | INTEGER | Number of emergency room visits by the patient in the preceding year |
| `number_inpatient_visits` | INTEGER | Number of inpatient admissions by the patient in the preceding year |
| `discharge_disposition` | VARCHAR | Discharge destination (e.g., Home, Rehab, Hospice) |
| `readmitted_flag` | BOOLEAN / VARCHAR | Target variable: whether the patient was readmitted within 30 days |

## Analysis Workflow
1. **SQL Staging & Extraction**: Standardize raw EHR data, handle null keys, and load into a structured table.
2. **SQL Profiling**: Perform initial statistical profiling (value counts, ranges, missingness analysis) inside the database.
3. **SQL Transformation**: Build clean views that encode categorical variables, bin ages, group ICD-9 codes (e.g., Circulatory, Respiratory, Digestive, Diabetes), and format final fields.
4. **Notebook Exploratory Analysis (EDA)**: Load clean data into Python, generate demographic distribution charts, and analyze readmission rates across features.
5. **Machine Learning Model**: Train classification models (Logistic Regression, Random Forest, or XGBoost), evaluate feature importances, and plot ROC/PR curves.
