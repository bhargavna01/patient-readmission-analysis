-- ============================================================================
-- SQL Script: 03_quality_checks.sql
-- Description: Performs data quality checks on the raw staging dataset.
-- ============================================================================

-- 1. Check for Duplicate Encounters
SELECT 
    encounter_id, 
    COUNT(*) AS occurrence_count
FROM staging.raw_clinical_records
GROUP BY encounter_id
HAVING COUNT(*) > 1;

-- 2. Verify Inclusion Criteria Compliance
-- Stay must be between 1 and 14 days
SELECT 
    COUNT(*) AS invalid_stay_count
FROM staging.raw_clinical_records
WHERE length_of_stay < 1 OR length_of_stay > 14;

-- 3. Check for Patients with Invalid Demographics
SELECT 
    COUNT(*) AS invalid_gender_count
FROM staging.raw_clinical_records
WHERE gender IS NULL OR gender IN ('Unknown/Invalid', '');

-- 4. Check for Empty or Null Critical Identifiers
SELECT 
    COUNT(*) FILTER (WHERE encounter_id IS NULL) AS null_encounters,
    COUNT(*) FILTER (WHERE patient_id IS NULL) AS null_patients
FROM staging.raw_clinical_records;

-- 5. Missing Diagnosis Code Check
SELECT 
    COUNT(*) AS missing_primary_diagnosis_count
FROM staging.raw_clinical_records
WHERE primary_diagnosis_code IS NULL OR primary_diagnosis_code = '' OR primary_diagnosis_code = '?';
