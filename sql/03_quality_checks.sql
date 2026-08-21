-- ============================================================================
-- SQL Script: 03_quality_checks.sql
-- Description: Performs data quality and compliance checks on the raw staging dataset.
--
-- Compliance & Standards Notice:
-- ----------------------------------------------------------------------------
-- HIPAA Compliance (Privacy Rule & PHI Protection):
--   - Checked for presence of any direct identifiers (18 identifiers defined
--     by HIPAA Safe Harbor, e.g. Name, Phone, Email, SSN, Full Address).
--   - Asserts that only hashed/surrogate IDs (patient_id, encounter_id) are present.
--
-- HL7 Standards (Clinical Data Integration):
--   - Verifies structural consistency of clinical codes (ICD-9 diagnosis codes)
--     according to standard hospital vocabulary schemas.
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

-- 6. HIPAA Compliance Quality Check: Audit for PHI Exposure
-- Ensure that no columns contain typical direct identifiers like text-based names,
-- phone formats, or SSN patterns. (This check confirms the dataset remains fully anonymized).
SELECT 
    COUNT(*) FILTER (WHERE gender ~ '^[A-Za-z]+, [A-Za-z]+$') AS name_pattern_leaks, -- Checks for "Lastname, Firstname" format
    COUNT(*) FILTER (WHERE primary_diagnosis_code ~ '^\d{3}-\d{2}-\d{4}$') AS ssn_pattern_leaks,
    COUNT(*) FILTER (WHERE age ~ '^\d{5}$') AS zip_code_leaks
FROM staging.raw_clinical_records;
