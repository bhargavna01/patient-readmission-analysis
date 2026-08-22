-- ============================================================================
-- SQL Script: 02_profiling.sql
-- Description: Queries to analyze raw data quality, distribution of values,
--              and identify missing data/outliers.
--
-- Compliance & Standards Notice:
-- ----------------------------------------------------------------------------
-- HIPAA Compliance (Privacy Rule & PHI Protection):
--   - All profiling queries operate on pseudonymized keys.
--   - Audits missingness distribution dynamically to identify fields with high
--     sparsity (like weight) which are dropped to protect patient uniqueness.
--
-- HL7 Standards (Clinical Data Integration):
--   - Checks data types and counts of standard hospital vocabularies.
-- ============================================================================

-- ============================================================================
-- DYNAMIC COLUMN-LEVEL DATA QUALITY PROFILING DASHBOARD
-- ============================================================================
-- Step-by-Step Explanation of the Query:
--
-- 1. CTE: unnested
--    - Uses 'to_jsonb(t)' to convert each database row into a JSONB object.
--    - Uses 'LATERAL jsonb_each_text()' to unpack the JSONB object key-value pairs
--      into virtual rows. The key represents the column name, and the value
--      represents the string value. This allows us to pivot 50 columns into
--      a key-value list dynamically without writing 50 separate column audits.
--    - The CASE statement standardizes character placeholders ('?', 'None', '')
--      used in clinical exports into true SQL NULL values, aligning with standard
--      HL7 missing value definitions and enabling HIPAA Safe Harbor completeness checks.
--
-- 2. CTE: summary
--    - Groups the unnested key-value records by column_name.
--    - 'COUNT(*) - COUNT(col_value)' calculates total nulls (since COUNT(col_value)
--      excludes NULLs).
--    - 'COUNT(DISTINCT col_value)' gets the number of unique attributes (critical
--      for validating high-cardinality patient identifiers).
--    - 'ROUND(... * 100, 2)' computes the exact missingness percentage.
--
-- 3. Final Query:
--    - Joins the metrics table with 'information_schema.columns' to pull the physical
--      data type of each column dynamically.
--    - Orders by s.null_percentage DESC to immediately highlight sparse columns.
-- ============================================================================

WITH unnested AS (
    SELECT 
        kv.key AS column_name,
        -- Treat '?', 'None', and empty strings as NULL values
        CASE 
            WHEN kv.value IN ('?', 'None', '') THEN NULL 
            ELSE kv.value 
        END AS col_value
    FROM public.diabetic_data t,
    LATERAL jsonb_each_text(to_jsonb(t)) kv
),
summary AS (
    SELECT 
        column_name,
        COUNT(*) - COUNT(col_value) AS nulls,
        COUNT(DISTINCT col_value) AS uniq_values,
        COUNT(*) AS total_data,
        ROUND(
            ((COUNT(*) - COUNT(col_value))::numeric / COUNT(*)::numeric) * 100, 
            2
        ) AS null_percentage
    FROM unnested
    GROUP BY column_name
)
SELECT 
    s.column_name,
    c.data_type,
    s.nulls,
    s.uniq_values,
    s.total_data,
    s.null_percentage
FROM summary s
LEFT JOIN information_schema.columns c 
    ON c.table_name = 'diabetic_data' 
   AND c.column_name = s.column_name
ORDER BY s.null_percentage DESC;

-- ============================================================================
-- SUPPLEMENTAL PROFILE QUERIES
-- ============================================================================

-- 1. Check Total Records, Distinct Patients, and Duplicate Encounters
SELECT 
    COUNT(*) AS total_encounters,
    COUNT(DISTINCT patient_id) AS distinct_patients,
    COUNT(*) - COUNT(DISTINCT encounter_id) AS duplicate_encounters
FROM staging.raw_clinical_records;

-- 2. Age Distribution
SELECT 
    age,
    COUNT(*) AS encounter_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM staging.raw_clinical_records
GROUP BY age
ORDER BY age;

-- 3. Readmission Distribution (Target Variable)
SELECT 
    readmitted_flag,
    COUNT(*) AS encounter_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM staging.raw_clinical_records
GROUP BY readmitted_flag;
