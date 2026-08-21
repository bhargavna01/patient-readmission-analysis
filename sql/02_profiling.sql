-- ============================================================================
-- SQL Script: 02_profiling.sql
-- Description: Queries to analyze raw data quality, distribution of values,
--              and identify missing data/outliers.
--
-- Compliance & Standards Notice:
-- ----------------------------------------------------------------------------
-- HIPAA Compliance (Privacy Rule & PHI Protection):
--   - All profiling queries operate on pseudonymized surrogate keys.
--   - No direct patient identifiers are queryable or displayed in these audits.
--   - Grouping operations are designed to evaluate system-level patterns
--     without exposing patient-specific diagnostic linkages.
--
-- HL7 Standards (Clinical Data Integration):
--   - Profiling diagnosis groups uses ICD-9 coding ranges to match standard
--     clinical terminologies defined by HL7 messaging dictionaries.
-- ============================================================================

-- 1. Check Total Records, Distinct Patients, and Duplicate Encounters
SELECT 
    COUNT(*) AS total_encounters,
    COUNT(DISTINCT patient_id) AS distinct_patients,
    COUNT(*) - COUNT(DISTINCT encounter_id) AS duplicate_encounters
FROM staging.raw_clinical_records;

-- 2. Null Value Auditing
SELECT 
    COUNT(*) FILTER (WHERE age IS NULL OR age = '') AS null_age_count,
    COUNT(*) FILTER (WHERE gender IS NULL OR gender = '') AS null_gender_count,
    COUNT(*) FILTER (WHERE primary_diagnosis_code IS NULL OR primary_diagnosis_code = '') AS null_diagnosis_count,
    COUNT(*) FILTER (WHERE admission_type IS NULL OR admission_type = '') AS null_admission_type_count
FROM staging.raw_clinical_records;

-- 3. Age Distribution
SELECT 
    age,
    COUNT(*) AS encounter_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM staging.raw_clinical_records
GROUP BY age
ORDER BY age;

-- 4. Readmission Distribution (Target Variable)
SELECT 
    readmitted_flag,
    COUNT(*) AS encounter_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM staging.raw_clinical_records
GROUP BY readmitted_flag;

-- 5. Demographics vs. Readmissions (Cross-tabulation sample)
SELECT 
    gender,
    COUNT(*) AS total_encounters,
    COUNT(*) FILTER (WHERE readmitted_flag = 'Yes') AS readmitted_count,
    ROUND(100.0 * COUNT(*) FILTER (WHERE readmitted_flag = 'Yes') / COUNT(*), 2) AS readmission_rate
FROM staging.raw_clinical_records
GROUP BY gender;

-- 6. Length of Stay Metrics by Readmission Status
SELECT 
    readmitted_flag,
    COUNT(*) AS encounters,
    MIN(length_of_stay) AS min_stay,
    MAX(length_of_stay) AS max_stay,
    AVG(length_of_stay) AS avg_stay,
    STDDEV(length_of_stay) AS stddev_stay
FROM staging.raw_clinical_records
GROUP BY readmitted_flag;
