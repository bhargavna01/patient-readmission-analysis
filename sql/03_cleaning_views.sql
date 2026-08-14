-- ============================================================================
-- SQL Script: 03_cleaning_views.sql
-- Description: Transforms and cleans raw staging data into an analytical view.
--              Includes null handling, age grouping, ICD-9 code categorization,
--              and boolean mapping for the readmission target variable.
-- ============================================================================

CREATE OR REPLACE VIEW staging.v_clean_patient_data AS
WITH formatted_data AS (
    SELECT 
        encounter_id,
        patient_id,
        
        -- Standardize gender
        CASE 
            WHEN UPPER(gender) IN ('M', 'MALE') THEN 'Male'
            WHEN UPPER(gender) IN ('F', 'FEMALE') THEN 'Female'
            ELSE 'Unknown/Other'
        END AS gender_clean,
        
        -- Standardize age bins or extract numeric values
        COALESCE(age, 'Unknown') AS age_group,
        
        -- Default numeric variables to 0 if null
        COALESCE(length_of_stay, 0) AS length_of_stay,
        COALESCE(num_lab_procedures, 0) AS num_lab_procedures,
        COALESCE(num_medications, 0) AS num_medications,
        COALESCE(number_emergency_visits, 0) AS number_emergency_visits,
        COALESCE(number_inpatient_visits, 0) AS number_inpatient_visits,
        
        -- Categorize admission type
        CASE 
            WHEN UPPER(admission_type) LIKE '%EMERGENCY%' THEN 'Emergency'
            WHEN UPPER(admission_type) LIKE '%URGENT%' THEN 'Urgent'
            WHEN UPPER(admission_type) LIKE '%ELECTIVE%' THEN 'Elective'
            ELSE 'Other/Unknown'
        END AS admission_type_clean,
        
        -- Standardize diagnosis code
        COALESCE(primary_diagnosis_code, 'Unknown') AS primary_diag_code,
        
        -- Standardize target variable
        CASE 
            WHEN UPPER(readmitted_flag) IN ('Y', 'YES', 'TRUE', '1') THEN 1
            ELSE 0
        END AS readmitted_flag_binary
        
    FROM staging.raw_clinical_records
    WHERE patient_id IS NOT NULL
      AND gender NOT IN ('Unknown/Invalid')
)
SELECT 
    *,
    -- Group ICD-9 codes into broader clinical classifications
    CASE
        WHEN primary_diag_code = 'Unknown' THEN 'Unknown'
        WHEN primary_diag_code LIKE '250%' THEN 'Diabetes'
        WHEN primary_diag_code ~ '^[0-9]' AND (CAST(SPLIT_PART(primary_diag_code, '.', 1) AS INT) BETWEEN 390 AND 459 OR CAST(SPLIT_PART(primary_diag_code, '.', 1) AS INT) = 785) THEN 'Circulatory'
        WHEN primary_diag_code ~ '^[0-9]' AND (CAST(SPLIT_PART(primary_diag_code, '.', 1) AS INT) BETWEEN 460 AND 519 OR CAST(SPLIT_PART(primary_diag_code, '.', 1) AS INT) = 786) THEN 'Respiratory'
        WHEN primary_diag_code ~ '^[0-9]' AND (CAST(SPLIT_PART(primary_diag_code, '.', 1) AS INT) BETWEEN 520 AND 579 OR CAST(SPLIT_PART(primary_diag_code, '.', 1) AS INT) = 787) THEN 'Digestive'
        WHEN primary_diag_code ~ '^[0-9]' AND (CAST(SPLIT_PART(primary_diag_code, '.', 1) AS INT) BETWEEN 580 AND 629 OR CAST(SPLIT_PART(primary_diag_code, '.', 1) AS INT) = 788) THEN 'Genitourinary'
        WHEN primary_diag_code ~ '^[0-9]' AND (CAST(SPLIT_PART(primary_diag_code, '.', 1) AS INT) BETWEEN 140 AND 239) THEN 'Neoplasms'
        WHEN primary_diag_code ~ '^[0-9]' AND (CAST(SPLIT_PART(primary_diag_code, '.', 1) AS INT) BETWEEN 710 AND 739) THEN 'Musculoskeletal'
        WHEN primary_diag_code ~ '^[0-9]' AND (CAST(SPLIT_PART(primary_diag_code, '.', 1) AS INT) BETWEEN 800 AND 999) THEN 'Injury'
        ELSE 'Other'
    END AS primary_diagnosis_group
FROM formatted_data;
