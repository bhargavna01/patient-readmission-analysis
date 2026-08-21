# Data Quality & Profiling Report

This report outlines the structural checks and data profiling conducted on the "Diabetes 130-US Hospitals" raw clinical records.

## 1. Missingness Audit
The raw dataset contains missing values represented by `?` rather than database `NULL`s. Key fields audited:
- **`weight`**: Missing in over 97% of records. Recommended action: Drop feature from predictive models due to sparsity.
- **`payer_code`**: Missing in over 40% of records. Recommended action: Exclude or categorize as "Unknown".
- **`medical_specialty`**: Missing in over 47% of records. Recommended action: Map to a broad specialty category or group as "Unknown/Other".
- **`race`**: Missing in ~2.2% of records.

## 2. Duplicate Encounter Check
- **Definition**: Multiple records containing the exact same `encounter_id`.
- **Finding**: No duplicate `encounter_id`s were found. The database primary key constraint on `encounter_id` is safe to enforce.
- **Note on patient repetition**: A single patient (`patient_nbr`) may have multiple encounters representing repeat admissions over the 10-year period. This is tracked by counting occurrences of `patient_nbr`.

## 3. Inclusion Criteria Compliance Checks
We verified that the staging dataset adheres to the official study constraints:
- **Length of Stay**: Must be between 1 and 14 days (records violating this range are flagged).
- **Diagnostics**: Primary diagnosis (`diag_1`) must have a valid value.
- **Medications**: At least one medication must have been administered during the encounter.

## 4. Categorical Inconsistencies & Cleaning Actions
- **Gender**: Found small numbers of "Unknown/Invalid" values. Action: Exclude these rows during cleaning.
- **Age**: Categorized in brackets (e.g., `[50-70)`). Standardized to clean categorical age groups.
- **Diagnosis Codes**: Multi-value ICD-9 codes (e.g. `250.01`, `428.0`) mapped to broad clinical categories (Circulatory, Respiratory, Digestive, Diabetes) using regex.
