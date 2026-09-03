-- ============================================================================
-- SQL Script: 06_analysis.sql
-- Description: Aggregated clinical analytics examining key drivers of 30-day
--              patient readmissions across all cleaned demographic, diagnostic,
--              laboratory, medication, and utilization features.
--
-- Compliance & Standards Notice:
-- ----------------------------------------------------------------------------
-- HIPAA Compliance:
--   - All metrics are calculated at aggregate cohort levels to protect patient privacy.
--   - No patient-identifying or single-encounter microdata is reported.
--
-- Clinical Context & HRRP Alignment:
--   - Focuses on 30-day readmission benchmarks aligned with the CMS HRRP guidelines.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. OVERALL 30-DAY READMISSION BENCHMARK
-- Clinical Rationale:
-- Establishes the baseline institutional readmission rate across all 101,763 encounters.
-- ----------------------------------------------------------------------------
SELECT 
    COUNT(*) AS total_encounters,
    COUNT(DISTINCT patient_id) AS unique_patients,
    SUM(readmitted_30d_binary) AS readmitted_within_30d_count,
    ROUND(100.0 * SUM(readmitted_30d_binary) / COUNT(*), 2) AS readmission_30d_rate_pct
FROM staging.v_clean_patient_data;

-- ----------------------------------------------------------------------------
-- 2. READMISSION RISK BY AGE GROUP
-- Clinical Rationale:
-- Older diabetic patients frequently experience polypharmacy and renal complications,
-- elevating readmission likelihood.
-- ----------------------------------------------------------------------------
SELECT 
    age_group,
    COUNT(*) AS total_encounters,
    SUM(readmitted_30d_binary) AS readmissions_30d,
    ROUND(100.0 * SUM(readmitted_30d_binary) / COUNT(*), 2) AS readmission_rate_pct
FROM staging.v_clean_patient_data
GROUP BY age_group
ORDER BY age_group;

-- ----------------------------------------------------------------------------
-- 3. READMISSION RISK BY PRIMARY CLINICAL DIAGNOSIS GROUP
-- Clinical Rationale:
-- Stratifying ICD-9 categories reveals which clinical conditions carry the highest 
-- post-discharge vulnerability (e.g., Circulatory, Respiratory, Diabetes).
-- ----------------------------------------------------------------------------
SELECT 
    primary_diagnosis_group,
    COUNT(*) AS total_encounters,
    SUM(readmitted_30d_binary) AS readmissions_30d,
    ROUND(100.0 * SUM(readmitted_30d_binary) / COUNT(*), 2) AS readmission_rate_pct
FROM staging.v_clean_patient_data
GROUP BY primary_diagnosis_group
ORDER BY readmission_rate_pct DESC;

-- ----------------------------------------------------------------------------
-- 4. PRIOR HEALTHCARE UTILIZATION IMPACT (Outpatient + Emergency + Inpatient)
-- Clinical Rationale:
-- Frequent prior healthcare utilization is one of the strongest predictive signals
-- of impending post-discharge decompensation.
-- ----------------------------------------------------------------------------
SELECT 
    CASE 
        WHEN total_prior_visits = 0 THEN '0 Prior Visits (Low)'
        WHEN total_prior_visits BETWEEN 1 AND 2 THEN '1-2 Prior Visits (Moderate)'
        WHEN total_prior_visits BETWEEN 3 AND 5 THEN '3-5 Prior Visits (High)'
        ELSE '6+ Prior Visits (Super-utilizer)'
    END AS prior_utilization_tier,
    COUNT(*) AS total_encounters,
    SUM(readmitted_30d_binary) AS readmissions_30d,
    ROUND(100.0 * SUM(readmitted_30d_binary) / COUNT(*), 2) AS readmission_rate_pct
FROM staging.v_clean_patient_data
GROUP BY 1
ORDER BY readmission_rate_pct ASC;

-- ----------------------------------------------------------------------------
-- 5. MEDICATION REGIMEN COMPLEXITY (Active Diabetes Medication Count)
-- Clinical Rationale:
-- Polypharmacy in diabetes management increases adverse drug events and non-adherence.
-- ----------------------------------------------------------------------------
SELECT 
    active_med_count,
    COUNT(*) AS total_encounters,
    SUM(readmitted_30d_binary) AS readmissions_30d,
    ROUND(100.0 * SUM(readmitted_30d_binary) / COUNT(*), 2) AS readmission_rate_pct
FROM staging.v_clean_patient_data
GROUP BY active_med_count
ORDER BY active_med_count;

-- ----------------------------------------------------------------------------
-- 6. GLYCEMIC CONTROL & TESTING IMPACT (HbA1c Result)
-- Clinical Rationale:
-- Evaluates whether receiving an HbA1c test and testing high (>8) influences readmission rates.
-- ----------------------------------------------------------------------------
SELECT 
    a1c_result_clean,
    COUNT(*) AS total_encounters,
    SUM(readmitted_30d_binary) AS readmissions_30d,
    ROUND(100.0 * SUM(readmitted_30d_binary) / COUNT(*), 2) AS readmission_rate_pct
FROM staging.v_clean_patient_data
GROUP BY a1c_result_clean
ORDER BY readmission_rate_pct DESC;

-- ----------------------------------------------------------------------------
-- 7. LENGTH OF STAY & RESOURCE CONSUMPTION BY READMISSION STATUS
-- Clinical Rationale:
-- Compares hospital resource consumption (mean stay, lab procedures, medications)
-- between patients who are readmitted vs those who are not.
-- ----------------------------------------------------------------------------
SELECT 
    CASE WHEN readmitted_30d_binary = 1 THEN 'Readmitted (<30 Days)' ELSE 'Not Readmitted' END AS cohort,
    COUNT(*) AS encounters,
    ROUND(AVG(length_of_stay), 2) AS mean_length_of_stay_days,
    ROUND(AVG(num_lab_procedures), 2) AS mean_lab_procedures,
    ROUND(AVG(num_medications), 2) AS mean_medications_prescribed
FROM staging.v_clean_patient_data
GROUP BY readmitted_30d_binary;
