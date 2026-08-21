-- ============================================================================
-- SQL Script: 05_validation.sql
-- Description: Runs post-cleaning validation checks on the clean patient view.
-- ============================================================================

-- 1. Compare Record Counts (Raw vs Clean)
-- Ensures no massive data loss during cleaning (excluding specific invalid gender values)
SELECT 
    (SELECT COUNT(*) FROM staging.raw_clinical_records) AS raw_count,
    (SELECT COUNT(*) FROM staging.v_clean_patient_data) AS clean_count,
    (SELECT COUNT(*) FROM staging.raw_clinical_records) - (SELECT COUNT(*) FROM staging.v_clean_patient_data) AS dropped_count;

-- 2. Verify Gender Column contains only Expected Values (Male, Female, Unknown/Other)
SELECT DISTINCT gender_clean 
FROM staging.v_clean_patient_data;

-- 3. Verify Target Variable values are strictly 0 or 1
SELECT 
    readmitted_flag_binary, 
    COUNT(*) AS counts
FROM staging.v_clean_patient_data
GROUP BY readmitted_flag_binary;

-- 4. Check for Nulls in Essential Clean Fields
SELECT 
    COUNT(*) FILTER (WHERE gender_clean IS NULL) AS null_genders,
    COUNT(*) FILTER (WHERE age_group IS NULL) AS null_ages,
    COUNT(*) FILTER (WHERE primary_diagnosis_group IS NULL) AS null_diagnosis_groups,
    COUNT(*) FILTER (WHERE readmitted_flag_binary IS NULL) AS null_targets
FROM staging.v_clean_patient_data;

-- 5. Range Check for Numeric Variables (Lengths of stay should be >= 0)
SELECT 
    COUNT(*) AS invalid_numeric_ranges
FROM staging.v_clean_patient_data
WHERE length_of_stay < 0 OR num_lab_procedures < 0 OR num_medications < 0;
