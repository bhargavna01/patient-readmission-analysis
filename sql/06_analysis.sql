-- ============================================================================
-- SQL Script: 06_analysis.sql
-- Description: Analyzes patient readmission rates based on clinical variables,
--              demographics, and prior visit history.
-- ============================================================================

-- 1. Overall Readmission Rate
SELECT 
    COUNT(*) AS total_encounters,
    SUM(readmitted_flag_binary) AS readmitted_count,
    ROUND(100.0 * SUM(readmitted_flag_binary) / COUNT(*), 2) AS readmission_rate
FROM staging.v_clean_patient_data;

-- 2. Readmission Rate by Age Group
SELECT 
    age_group,
    COUNT(*) AS total_encounters,
    SUM(readmitted_flag_binary) AS readmitted_count,
    ROUND(100.0 * SUM(readmitted_flag_binary) / COUNT(*), 2) AS readmission_rate
FROM staging.v_clean_patient_data
GROUP BY age_group
ORDER BY age_group;

-- 3. Readmission Rate by Primary Diagnosis Group
SELECT 
    primary_diagnosis_group,
    COUNT(*) AS total_encounters,
    SUM(readmitted_flag_binary) AS readmitted_count,
    ROUND(100.0 * SUM(readmitted_flag_binary) / COUNT(*), 2) AS readmission_rate
FROM staging.v_clean_patient_data
GROUP BY primary_diagnosis_group
ORDER BY readmission_rate DESC;

-- 4. Utilization History Impact (Emergency vs Inpatient Visits)
SELECT 
    CASE 
        WHEN number_emergency_visits = 0 THEN '0 Emergency Visits'
        WHEN number_emergency_visits BETWEEN 1 AND 2 THEN '1-2 Emergency Visits'
        ELSE '3+ Emergency Visits'
    END AS emergency_visit_tier,
    COUNT(*) AS total_encounters,
    SUM(readmitted_flag_binary) AS readmitted_count,
    ROUND(100.0 * SUM(readmitted_flag_binary) / COUNT(*), 2) AS readmission_rate
FROM staging.v_clean_patient_data
GROUP BY emergency_visit_tier
ORDER BY emergency_visit_tier;

-- 5. Average Length of Stay by Readmission Status
SELECT 
    CASE WHEN readmitted_flag_binary = 1 THEN 'Readmitted' ELSE 'Not Readmitted' END AS readmission_status,
    COUNT(*) AS encounters,
    ROUND(AVG(length_of_stay), 2) AS avg_length_of_stay,
    ROUND(AVG(num_lab_procedures), 2) AS avg_num_lab_procedures,
    ROUND(AVG(num_medications), 2) AS avg_num_medications
FROM staging.v_clean_patient_data
GROUP BY readmitted_flag_binary;
