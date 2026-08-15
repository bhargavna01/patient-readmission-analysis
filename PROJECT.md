# Project: Patient Readmission Analysis

## Overview
Hospital readmissions are a major focus for healthcare systems because they are costly and often serve as an indicator of the quality of patient care. This project aims to analyze historical patient clinical records to identify key drivers of readmissions (specifically within 30 days of discharge) and build a predictive model to identify high-risk patients.

## Data Source & Database Hosting
- **Data Source**: [UCI Diabetes 130-US Hospitals (1999-2008) Dataset](https://archive.ics.uci.edu/dataset/296/diabetes+130-us+hospitals+for+years+1999-2008)
- **Database Hosting**: [Neon Serverless PostgreSQL Branch](https://console.neon.tech/app/projects/cold-brook-55376009/branches/br-flat-glade-ayhi7hms/)

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

## Dataset Profile
- **Instances**: 101,766
- **Attributes**: 50 (including identifiers, demographics, clinical features, test results, medications, and outcomes)
- **Timeframe**: 10 years (1999–2008) of clinical care across 130 US hospitals and integrated delivery networks.
- **Missing Values**: Present (encoded as `?` in the raw CSV, e.g., in `weight`, `payer_code`, and `medical_specialty`).

### Inclusion Criteria
An encounter was included in the dataset only if it satisfied the following:
1. It is an inpatient encounter (hospital admission).
2. It is a diabetic encounter (any kind of diabetes was entered into the system as a diagnosis).
3. The length of stay was between 1 day and 14 days.
4. Laboratory tests were performed during the encounter.
5. Medications were administered during the encounter.

## Data Dictionary (UCI Schema)

| Category | Column Name | Data Type | Description |
|---|---|---|---|
| **Identifiers** | `encounter_id` | INTEGER | Unique identifier of an encounter |
| | `patient_nbr` | INTEGER | Unique identifier of a patient |
| **Demographics** | `race` | VARCHAR | Caucasian, Asian, African American, Hispanic, Other |
| | `gender` | VARCHAR | Male, Female, Unknown/Invalid |
| | `age` | VARCHAR | Grouped in 10-year intervals: `[0, 10)`, `[10, 20)`, ..., `[90, 100)` |
| | `weight` | VARCHAR | Patient weight in pounds (highly missing) |
| **Admission/Discharge** | `admission_type_id` | INTEGER | Code corresponding to 9 values (Emergency, Urgent, Elective, Newborn, etc.) |
| | `discharge_disposition_id` | INTEGER | Code corresponding to 29 values (Discharged to home, expired, etc.) |
| | `admission_source_id` | INTEGER | Code corresponding to 21 values (Physician referral, Emergency Room, etc.) |
| | `time_in_hospital` | INTEGER | Number of days between admission and discharge (1-14) |
| | `payer_code` | VARCHAR | Code corresponding to 17 values (e.g., Blue Cross/Blue Shield, Self Pay, Medicare) |
| | `medical_specialty` | VARCHAR | Specialty of the admitting physician (e.g., Cardiology, Internal Medicine, Pediatrics) |
| **Diagnostics & Utilization** | `num_lab_procedures` | INTEGER | Number of lab tests performed during the encounter |
| | `num_procedures` | INTEGER | Number of non-lab procedures performed during the encounter |
| | `num_medications` | INTEGER | Number of unique medications prescribed during the encounter |
| | `number_outpatient` | INTEGER | Number of outpatient visits of the patient in the preceding year |
| | `number_emergency` | INTEGER | Number of emergency visits of the patient in the preceding year |
| | `number_inpatient` | INTEGER | Number of inpatient visits of the patient in the preceding year |
| | `diag_1` | VARCHAR | Primary diagnosis code (first 3 digits of ICD-9) |
| | `diag_2` | VARCHAR | Secondary diagnosis code (first 3 digits of ICD-9) |
| | `diag_3` | VARCHAR | Additional secondary diagnosis code (first 3 digits of ICD-9) |
| | `number_diagnoses` | INTEGER | Number of diagnoses entered into the system |
| **Lab/Test Results** | `max_glu_serum` | VARCHAR | Result of glucose serum test (`>200`, `>300`, `normal`, `none` if not taken) |
| | `A1Cresult` | VARCHAR | Result of HbA1c test (`>8`, `>7`, `normal`, `none` if not taken) |
| **Medications** | 24 specific drugs | VARCHAR | Indicators for 24 specific diabetes medications (e.g., `metformin`, `repaglinide`, `glipizide`, `glyburide`, `insulin`, etc.). Values: `up` (dose increased), `down` (dose decreased), `steady` (dose stable), `no` (not prescribed) |
| | `change` | VARCHAR | Indicates if there was a change in diabetic medications (`change`, `no change`) |
| | `diabetesMed` | VARCHAR | Indicates if any diabetic medication was prescribed (`yes`, `no`) |
| **Target Variable** | `readmitted` | VARCHAR | **Target**: `<30` (readmitted in <30 days), `>30` (readmitted in >30 days), `NO` (no readmission) |


## Analysis Workflow
1. **SQL Staging & Extraction**: Standardize raw EHR data, handle null keys, and load into a structured table.
2. **SQL Profiling**: Perform initial statistical profiling (value counts, ranges, missingness analysis) inside the database.
3. **SQL Transformation**: Build clean views that encode categorical variables, bin ages, group ICD-9 codes (e.g., Circulatory, Respiratory, Digestive, Diabetes), and format final fields.
4. **Notebook Exploratory Analysis (EDA)**: Load clean data into Python, generate demographic distribution charts, and analyze readmission rates across features.
5. **Machine Learning Model**: Train classification models (Logistic Regression, Random Forest, or XGBoost), evaluate feature importances, and plot ROC/PR curves.
