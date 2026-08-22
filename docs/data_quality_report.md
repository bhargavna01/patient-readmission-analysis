# Data Quality & Profiling Report

This report outlines the structural checks, missingness audits, and data profiling metrics conducted on the "Diabetes 130-US Hospitals" raw clinical records.

## 1. Missingness Audit
The raw dataset contains missing values represented by `?` rather than database `NULL`s. Key fields audited:
- **`weight`**: Missing in **96.86%** of records (98,569 nulls). Recommended action: Drop feature from predictive models due to sparsity.
- **`max_glu_serum`**: Missing in **94.75%** of records (96,420 nulls).
- **`A1Cresult`**: Missing in **83.28%** of records (84,748 nulls).
- **`medical_specialty`**: Missing in **49.08%** of records (49,949 nulls). Recommended action: Map to a broad specialty category or group as "Unknown/Other".
- **`payer_code`**: Missing in **39.56%** of records (40,256 nulls). Recommended action: Exclude or categorize as "Unknown".
- **`race`**: Missing in **2.23%** of records (2,273 nulls).
- **`diag_3`**: Missing in **1.40%** of records (1,423 nulls).
- **`diag_2`**: Missing in **0.35%** of records (358 nulls).
- **`diag_1`**: Missing in **0.02%** of records (21 nulls).

---

## 2. Duplicate Encounter Check
- **Definition**: Multiple records containing the exact same `encounter_id`.
- **Finding**: No duplicate `encounter_id`s were found (0 duplicates). The database primary key constraint on `encounter_id` is safe to enforce.
- **Note on patient repetition**: A single patient (`patient_nbr`) may have multiple encounters representing repeat admissions over the 10-year period. This is tracked by counting occurrences of `patient_nbr`.

---

## 3. Inclusion Criteria Compliance Checks
We verified that the staging dataset adheres to the official study constraints:
- **Length of Stay**: Must be between 1 and 14 days (all 101,766 records in the dataset comply).
- **Diagnostics**: Primary diagnosis (`diag_1`) must have a valid value.
- **Medications**: At least one medication must have been administered during the encounter.

---

## 4. Categorical Inconsistencies & Cleaning Actions
- **Gender**: Found 3 "Unknown/Invalid" values. Action: Exclude these rows during cleaning.
- **Age**: Categorized in brackets (e.g., `[50-60)`). Standardized to clean categorical age groups.
- **Diagnosis Codes**: Multi-value ICD-9 codes (e.g. `250.01`, `428.0`) mapped to broad clinical categories (Circulatory, Respiratory, Digestive, Diabetes) using regex.

---

## 5. Column-Level Data Quality Metrics
The table below lists all 50 columns in the raw dataset, audited for data type, null counts, unique values, and missingness percentage.

| Column Name | Data Type | Null Count | Unique Values | Total Rows | Null Percentage |
| :--- | :---: | :---: | :---: | :---: | :---: |
| `weight` | text | 98,569 | 9 | 101,766 | 96.86% |
| `max_glu_serum` | text | 96,420 | 3 | 101,766 | 94.75% |
| `A1Cresult` | text | 84,748 | 3 | 101,766 | 83.28% |
| `medical_specialty` | text | 49,949 | 72 | 101,766 | 49.08% |
| `payer_code` | text | 40,256 | 17 | 101,766 | 39.56% |
| `race` | text | 2,273 | 5 | 101,766 | 2.23% |
| `diag_3` | text | 1,423 | 789 | 101,766 | 1.40% |
| `diag_2` | text | 358 | 748 | 101,766 | 0.35% |
| `diag_1` | text | 21 | 716 | 101,766 | 0.02% |
| `diabetesMed` | text | 0 | 2 | 101,766 | 0.00% |
| `discharge_disposition_id` | text | 0 | 26 | 101,766 | 0.00% |
| `encounter_id` | text | 0 | 101,766 | 101,766 | 0.00% |
| `examide` | text | 0 | 1 | 101,766 | 0.00% |
| `gender` | text | 0 | 3 | 101,766 | 0.00% |
| `glimepiride` | text | 0 | 4 | 101,766 | 0.00% |
| `glimepiride-pioglitazone` | text | 0 | 2 | 101,766 | 0.00% |
| `glipizide` | text | 0 | 4 | 101,766 | 0.00% |
| `glipizide-metformin` | text | 0 | 2 | 101,766 | 0.00% |
| `glyburide` | text | 0 | 4 | 101,766 | 0.00% |
| `glyburide-metformin` | text | 0 | 4 | 101,766 | 0.00% |
| `insulin` | text | 0 | 4 | 101,766 | 0.00% |
| `metformin` | text | 0 | 4 | 101,766 | 0.00% |
| `metformin-pioglitazone` | text | 0 | 2 | 101,766 | 0.00% |
| `metformin-rosiglitazone` | text | 0 | 2 | 101,766 | 0.00% |
| `miglitol` | text | 0 | 4 | 101,766 | 0.00% |
| `nateglinide` | text | 0 | 4 | 101,766 | 0.00% |
| `num_lab_procedures` | text | 0 | 118 | 101,766 | 0.00% |
| `num_medications` | text | 0 | 75 | 101,766 | 0.00% |
| `num_procedures` | text | 0 | 7 | 101,766 | 0.00% |
| `number_diagnoses` | text | 0 | 16 | 101,766 | 0.00% |
| `number_emergency` | text | 0 | 33 | 101,766 | 0.00% |
| `number_inpatient` | text | 0 | 21 | 101,766 | 0.00% |
| `number_outpatient` | text | 0 | 39 | 101,766 | 0.00% |
| `patient_nbr` | text | 0 | 71,518 | 101,766 | 0.00% |
| `pioglitazone` | text | 0 | 4 | 101,766 | 0.00% |
| `readmitted` | text | 0 | 3 | 101,766 | 0.00% |
| `rosiglitazone` | text | 0 | 4 | 101,766 | 0.00% |
| `time_in_hospital` | text | 0 | 14 | 101,766 | 0.00% |
| `tolazamide` | text | 0 | 3 | 101,766 | 0.00% |
| `tolbutamide` | text | 0 | 2 | 101,766 | 0.00% |
| `troglitazone` | text | 0 | 2 | 101,766 | 0.00% |
| `repaglinide` | text | 0 | 4 | 101,766 | 0.00% |
| `acarbose` | text | 0 | 4 | 101,766 | 0.00% |
| `acetohexamide` | text | 0 | 2 | 101,766 | 0.00% |
| `admission_source_id` | text | 0 | 17 | 101,766 | 0.00% |
| `admission_type_id` | text | 0 | 8 | 101,766 | 0.00% |
| `age` | text | 0 | 10 | 101,766 | 0.00% |
| `change` | text | 0 | 2 | 101,766 | 0.00% |
| `chlorpropamide` | text | 0 | 4 | 101,766 | 0.00% |
| `citoglipton` | text | 0 | 1 | 101,766 | 0.00% |
