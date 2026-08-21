# Data Dictionary: Patient Readmission Analysis

This document describes the structure and schemas of the raw staging dataset and the clean analytical tables used for the Patient Readmission Analysis project.

## 1. Raw Dataset Schema (`staging.raw_clinical_records`)

| Category | Column Name | Data Type | Description |
|---|---|---|---|
| **Identifiers** | `encounter_id` | INTEGER | Unique identifier of an encounter |
| | `patient_nbr` | INTEGER | Unique identifier of a patient |
| **Demographics** | `race` | VARCHAR | Caucasian, Asian, African American, Hispanic, Other |
| | `gender` | VARCHAR | Male, Female, Unknown/Invalid |
| | `age` | VARCHAR | Grouped in 10-year intervals: `[0, 10)`, `[10, 20)`, ..., `[90, 100)` |
| | `weight` | VARCHAR | Patient weight in pounds (highly missing, encoded with `?`) |
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

---

## 2. Transformed Clean Schema (`staging.v_clean_patient_data` / `clean_diabetic_data.csv`)

These schemas are used for modeling and analysis:

| Column Name | Data Type | Source/Cleaning Logic |
|---|---|---|
| `encounter_id` | INTEGER | Kept from raw. |
| `patient_id` / `patient_nbr` | INTEGER | Kept from raw. |
| `gender_clean` | VARCHAR | Standardized to `Male` or `Female`. Records with 'Unknown/Invalid' are dropped. |
| `age_group` | VARCHAR | Cleaned; default to 'Unknown' if missing. |
| `length_of_stay` / `time_in_hospital`| INTEGER | Days spent in hospital. Nulls filled with 0. |
| `primary_diagnosis_group` | VARCHAR | ICD-9 codes in `diag_1` grouped into Circulatory, Respiratory, Digestive, Diabetes, Injury, Genitourinary, Neoplasms, Musculoskeletal, Other, or Unknown. |
| `readmitted_flag_binary` / `readmitted_binary` | INTEGER | Target variable: `1` if readmitted within 30 days (`<30`), otherwise `0`. |
