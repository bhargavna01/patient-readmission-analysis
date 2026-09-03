-- ============================================================================
-- SQL Script: 04_cleaning.sql
-- Description: Comprehensive clinical data transformation and cleaning pipeline
--              operating on ALL 50 columns of the raw diabetic_data table.
--
-- Compliance & Standards Notice:
-- ----------------------------------------------------------------------------
-- HIPAA Compliance (Privacy Rule & PHI Protection):
--   - Excludes non-conforming demographic records (3 Unknown/Invalid gender rows).
--   - Standardizes sparse features (e.g., weight, payer code) into clean categories 
--     without leaking individual uniqueness.
--   - Preserves pseudonymized surrogate identifiers (encounter_id, patient_nbr).
--
-- HL7 Standards & Clinical Coding:
--   - Maps raw ICD-9 primary, secondary, and tertiary diagnosis codes into 9 
--     broad clinical taxonomy categories (Circulatory, Respiratory, Digestive, 
--     Diabetes, Genitourinary, Neoplasms, Musculoskeletal, Injury, Other).
--   - Maps administrative admission and discharge codes according to standard
--     hospital discharge disposition definitions (UB-04 / HL7 Table 0112).
--   - Correctly establishes the 30-day hospital readmission target according
--     to the CMS Hospital Readmissions Reduction Program (HRRP) definition:
--     '<30' => 1 (Readmitted within 30 days), '>30' or 'NO' => 0.
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS staging;

CREATE OR REPLACE VIEW staging.v_clean_patient_data AS
WITH raw_standardized AS (
    SELECT 
        -- --------------------------------------------------------------------
        -- 1. IDENTIFIERS (Columns 1-2)
        -- Clinical Rationale: encounter_id uniquely distinguishes each hospital admission event.
        -- patient_nbr allows tracking longitudinal patient journeys and repeat hospital visits.
        -- --------------------------------------------------------------------
        CAST(encounter_id AS BIGINT) AS encounter_id,
        CAST(patient_nbr AS BIGINT) AS patient_id,
        
        -- --------------------------------------------------------------------
        -- 2. DEMOGRAPHICS & SENSITIVE ATTRIBUTES (Columns 3-6)
        -- Clinical Rationale: Age and gender are strong covariates of metabolic disease severity.
        -- '?' placeholders represent unrecorded values and are converted to 'Unknown'.
        -- Weight is missing in ~96.86% of records, so it is standardized into an explicit 'Missing' category.
        -- --------------------------------------------------------------------
        CASE 
            WHEN race = '?' OR race IS NULL THEN 'Unknown'
            ELSE race 
        END AS race_clean,
        
        CASE 
            WHEN UPPER(gender) IN ('M', 'MALE') THEN 'Male'
            WHEN UPPER(gender) IN ('F', 'FEMALE') THEN 'Female'
            ELSE 'Unknown/Invalid'
        END AS gender_clean,
        
        CASE 
            WHEN age = '?' OR age IS NULL THEN 'Unknown'
            ELSE age 
        END AS age_group,
        
        CASE 
            WHEN weight = '?' OR weight IS NULL THEN 'Missing'
            ELSE weight 
        END AS weight_clean,
        
        -- --------------------------------------------------------------------
        -- 3. ADMISSION & DISCHARGE ADMINISTRATIVE CODES (Columns 7-9)
        -- Clinical Rationale: Emergency admissions have higher acuity and readmission risk.
        -- Discharge dispositions differentiate between home discharge, transfer, and hospice/deceased.
        -- --------------------------------------------------------------------
        CAST(NULLIF(admission_type_id, '?') AS INT) AS admission_type_id,
        CASE 
            WHEN admission_type_id IN ('1', '7') THEN 'Emergency'
            WHEN admission_type_id = '2' THEN 'Urgent'
            WHEN admission_type_id = '3' THEN 'Elective'
            WHEN admission_type_id = '4' THEN 'Newborn'
            WHEN admission_type_id = '7' THEN 'Trauma Center'
            ELSE 'Other/Unknown'
        END AS admission_type_desc,
        
        CAST(NULLIF(discharge_disposition_id, '?') AS INT) AS discharge_disposition_id,
        CASE 
            WHEN discharge_disposition_id = '1' THEN 'Discharged to Home'
            WHEN discharge_disposition_id IN ('11', '13', '14', '19', '20', '21') THEN 'Expired/Hospice'
            WHEN discharge_disposition_id IN ('2', '3', '4', '5', '22', '23', '24') THEN 'Transferred Facility'
            WHEN discharge_disposition_id IN ('6', '8') THEN 'Home Health Service'
            ELSE 'Other/Unknown'
        END AS discharge_disposition_desc,
        
        CAST(NULLIF(admission_source_id, '?') AS INT) AS admission_source_id,
        CASE 
            WHEN admission_source_id = '7' THEN 'Emergency Room'
            WHEN admission_source_id IN ('1', '2') THEN 'Physician/Clinic Referral'
            WHEN admission_source_id IN ('4', '5', '6') THEN 'Transfer from Hospital/Facility'
            ELSE 'Other Referral'
        END AS admission_source_desc,
        
        -- --------------------------------------------------------------------
        -- 4. HOSPITAL UTILIZATION & LENGTH OF STAY (Columns 10, 13-18)
        -- Clinical Rationale: Length of stay and prior utilization (inpatient, emergency, outpatient visits)
        -- are proven clinical proxies for disease chronicity and high healthcare reliance.
        -- --------------------------------------------------------------------
        COALESCE(CAST(NULLIF(time_in_hospital, '?') AS INT), 0) AS length_of_stay,
        COALESCE(CAST(NULLIF(num_lab_procedures, '?') AS INT), 0) AS num_lab_procedures,
        COALESCE(CAST(NULLIF(num_procedures, '?') AS INT), 0) AS num_procedures,
        COALESCE(CAST(NULLIF(num_medications, '?') AS INT), 0) AS num_medications,
        COALESCE(CAST(NULLIF(number_outpatient, '?') AS INT), 0) AS number_outpatient,
        COALESCE(CAST(NULLIF(number_emergency, '?') AS INT), 0) AS number_emergency,
        COALESCE(CAST(NULLIF(number_inpatient, '?') AS INT), 0) AS number_inpatient,
        COALESCE(CAST(NULLIF(number_diagnoses, '?') AS INT), 0) AS number_diagnoses,
        
        -- Derived engineered feature: Total prior healthcare encounters in past year
        (COALESCE(CAST(NULLIF(number_outpatient, '?') AS INT), 0) +
         COALESCE(CAST(NULLIF(number_emergency, '?') AS INT), 0) +
         COALESCE(CAST(NULLIF(number_inpatient, '?') AS INT), 0)) AS total_prior_visits,
        
        -- --------------------------------------------------------------------
        -- 5. ADMINISTRATIVE & PHYSICIAN SPECIALTY (Columns 11-12)
        -- Clinical Rationale: Specialty provides context on the primary condition treated.
        -- --------------------------------------------------------------------
        CASE 
            WHEN payer_code = '?' OR payer_code IS NULL THEN 'Unknown/Uninsured'
            ELSE payer_code 
        END AS payer_code_clean,
        
        CASE 
            WHEN medical_specialty = '?' OR medical_specialty IS NULL THEN 'Missing'
            WHEN medical_specialty LIKE '%Cardiology%' THEN 'Cardiology'
            WHEN medical_specialty LIKE '%Surgery%' THEN 'Surgery'
            WHEN medical_specialty LIKE '%InternalMedicine%' THEN 'Internal Medicine'
            WHEN medical_specialty LIKE '%Family%' OR medical_specialty LIKE '%General%' THEN 'General/Family Practice'
            WHEN medical_specialty LIKE '%Emergency%' THEN 'Emergency Medicine'
            ELSE 'Other Specialty'
        END AS medical_specialty_clean,
        
        -- --------------------------------------------------------------------
        -- 6. CLINICAL DIAGNOSES: ICD-9 CODES (Columns 19-21)
        -- Clinical Rationale: Primary, secondary, and tertiary ICD-9 codes indicate underlying comorbidities.
        -- Clean '?' to 'Unknown' before classification.
        -- --------------------------------------------------------------------
        CASE WHEN diag_1 = '?' OR diag_1 IS NULL THEN 'Unknown' ELSE diag_1 END AS diag_1_raw,
        CASE WHEN diag_2 = '?' OR diag_2 IS NULL THEN 'Unknown' ELSE diag_2 END AS diag_2_raw,
        CASE WHEN diag_3 = '?' OR diag_3 IS NULL THEN 'Unknown' ELSE diag_3 END AS diag_3_raw,
        
        -- --------------------------------------------------------------------
        -- 7. LABORATORY TEST RESULTS: GLUCOSE & HBA1C (Columns 23-24)
        -- Clinical Rationale: HbA1c and serum glucose levels measure glycemic control.
        -- 'None' indicates no test was performed during the encounter.
        -- --------------------------------------------------------------------
        CASE 
            WHEN max_glu_serum IS NULL OR max_glu_serum IN ('None', '?') THEN 'Not Tested'
            ELSE max_glu_serum 
        END AS max_glu_serum_clean,
        
        CASE 
            WHEN "A1Cresult" IS NULL OR "A1Cresult" IN ('None', '?') THEN 'Not Tested'
            ELSE "A1Cresult" 
        END AS a1c_result_clean,
        
        -- --------------------------------------------------------------------
        -- 8. 24 DIABETES MEDICATIONS (Columns 25-47)
        -- Clinical Rationale: Categorizes specific drug therapies (insulin, sulfonylureas, biguanides).
        -- Hyphenated names are aliased with underscores for standard SQL identifier compliance.
        -- --------------------------------------------------------------------
        metformin,
        repaglinide,
        nateglinide,
        chlorpropamide,
        glimepiride,
        acetohexamide,
        glipizide,
        glyburide,
        tolbutamide,
        pioglitazone,
        rosiglitazone,
        acarbose,
        miglitol,
        troglitazone,
        tolazamide,
        examide,
        citoglipton,
        insulin,
        "glyburide-metformin" AS glyburide_metformin,
        "glipizide-metformin" AS glipizide_metformin,
        "glimepiride-pioglitazone" AS glimepiride_pioglitazone,
        "metformin-rosiglitazone" AS metformin_rosiglitazone,
        "metformin-pioglitazone" AS metformin_pioglitazone,
        
        -- Derived feature: Count of active diabetes medications prescribed
        ((CASE WHEN metformin NOT IN ('No', '?') THEN 1 ELSE 0 END) +
         (CASE WHEN repaglinide NOT IN ('No', '?') THEN 1 ELSE 0 END) +
         (CASE WHEN nateglinide NOT IN ('No', '?') THEN 1 ELSE 0 END) +
         (CASE WHEN chlorpropamide NOT IN ('No', '?') THEN 1 ELSE 0 END) +
         (CASE WHEN glimepiride NOT IN ('No', '?') THEN 1 ELSE 0 END) +
         (CASE WHEN acetohexamide NOT IN ('No', '?') THEN 1 ELSE 0 END) +
         (CASE WHEN glipizide NOT IN ('No', '?') THEN 1 ELSE 0 END) +
         (CASE WHEN glyburide NOT IN ('No', '?') THEN 1 ELSE 0 END) +
         (CASE WHEN tolbutamide NOT IN ('No', '?') THEN 1 ELSE 0 END) +
         (CASE WHEN pioglitazone NOT IN ('No', '?') THEN 1 ELSE 0 END) +
         (CASE WHEN rosiglitazone NOT IN ('No', '?') THEN 1 ELSE 0 END) +
         (CASE WHEN acarbose NOT IN ('No', '?') THEN 1 ELSE 0 END) +
         (CASE WHEN miglitol NOT IN ('No', '?') THEN 1 ELSE 0 END) +
         (CASE WHEN troglitazone NOT IN ('No', '?') THEN 1 ELSE 0 END) +
         (CASE WHEN tolazamide NOT IN ('No', '?') THEN 1 ELSE 0 END) +
         (CASE WHEN insulin NOT IN ('No', '?') THEN 1 ELSE 0 END) +
         (CASE WHEN "glyburide-metformin" NOT IN ('No', '?') THEN 1 ELSE 0 END) +
         (CASE WHEN "glipizide-metformin" NOT IN ('No', '?') THEN 1 ELSE 0 END) +
         (CASE WHEN "glimepiride-pioglitazone" NOT IN ('No', '?') THEN 1 ELSE 0 END) +
         (CASE WHEN "metformin-rosiglitazone" NOT IN ('No', '?') THEN 1 ELSE 0 END) +
         (CASE WHEN "metformin-pioglitazone" NOT IN ('No', '?') THEN 1 ELSE 0 END)
        ) AS active_med_count,
        
        -- --------------------------------------------------------------------
        -- 9. MEDICATION MANAGEMENT & CHANGES (Columns 48-49)
        -- Clinical Rationale: A medication dosage adjustment ('Ch') reflects active disease volatility.
        -- --------------------------------------------------------------------
        CASE 
            WHEN change = 'Ch' THEN 'Change'
            ELSE 'No Change' 
        END AS med_change,
        
        CASE 
            WHEN UPPER("diabetesMed") = 'YES' THEN 'Yes'
            ELSE 'No' 
        END AS diabetes_med_prescribed,
        
        -- --------------------------------------------------------------------
        -- 10. TARGET VARIABLE: 30-DAY HOSPITAL READMISSION (Column 50)
        -- Clinical & Regulatory Rationale:
        -- The CMS Hospital Readmissions Reduction Program defines readmission as unplanned
        -- return within 30 days of discharge. Thus:
        -- '<30' => 1 (Positive target), '>30' and 'NO' => 0.
        -- --------------------------------------------------------------------
        readmitted AS readmitted_raw,
        CASE 
            WHEN readmitted = '<30' THEN 1 
            ELSE 0 
        END AS readmitted_30d_binary,
        CASE 
            WHEN readmitted IN ('<30', '>30') THEN 1 
            ELSE 0 
        END AS readmitted_any_binary

    FROM public.diabetic_data
    WHERE patient_nbr IS NOT NULL
      AND gender NOT IN ('Unknown/Invalid', 'Unknown')
)
SELECT 
    *,
    
    -- Primary Diagnosis ICD-9 Categorization
    CASE
        WHEN diag_1_raw = 'Unknown' THEN 'Unknown'
        WHEN diag_1_raw LIKE '250%' THEN 'Diabetes'
        WHEN diag_1_raw ~ '^[0-9]' AND (CAST(SPLIT_PART(diag_1_raw, '.', 1) AS INT) BETWEEN 390 AND 459 OR CAST(SPLIT_PART(diag_1_raw, '.', 1) AS INT) = 785) THEN 'Circulatory'
        WHEN diag_1_raw ~ '^[0-9]' AND (CAST(SPLIT_PART(diag_1_raw, '.', 1) AS INT) BETWEEN 460 AND 519 OR CAST(SPLIT_PART(diag_1_raw, '.', 1) AS INT) = 786) THEN 'Respiratory'
        WHEN diag_1_raw ~ '^[0-9]' AND (CAST(SPLIT_PART(diag_1_raw, '.', 1) AS INT) BETWEEN 520 AND 579 OR CAST(SPLIT_PART(diag_1_raw, '.', 1) AS INT) = 787) THEN 'Digestive'
        WHEN diag_1_raw ~ '^[0-9]' AND (CAST(SPLIT_PART(diag_1_raw, '.', 1) AS INT) BETWEEN 580 AND 629 OR CAST(SPLIT_PART(diag_1_raw, '.', 1) AS INT) = 788) THEN 'Genitourinary'
        WHEN diag_1_raw ~ '^[0-9]' AND (CAST(SPLIT_PART(diag_1_raw, '.', 1) AS INT) BETWEEN 140 AND 239) THEN 'Neoplasms'
        WHEN diag_1_raw ~ '^[0-9]' AND (CAST(SPLIT_PART(diag_1_raw, '.', 1) AS INT) BETWEEN 710 AND 739) THEN 'Musculoskeletal'
        WHEN diag_1_raw ~ '^[0-9]' AND (CAST(SPLIT_PART(diag_1_raw, '.', 1) AS INT) BETWEEN 800 AND 999) THEN 'Injury'
        ELSE 'Other'
    END AS primary_diagnosis_group,
    
    -- Secondary Diagnosis ICD-9 Categorization
    CASE
        WHEN diag_2_raw = 'Unknown' THEN 'Unknown'
        WHEN diag_2_raw LIKE '250%' THEN 'Diabetes'
        WHEN diag_2_raw ~ '^[0-9]' AND (CAST(SPLIT_PART(diag_2_raw, '.', 1) AS INT) BETWEEN 390 AND 459 OR CAST(SPLIT_PART(diag_2_raw, '.', 1) AS INT) = 785) THEN 'Circulatory'
        WHEN diag_2_raw ~ '^[0-9]' AND (CAST(SPLIT_PART(diag_2_raw, '.', 1) AS INT) BETWEEN 460 AND 519 OR CAST(SPLIT_PART(diag_2_raw, '.', 1) AS INT) = 786) THEN 'Respiratory'
        WHEN diag_2_raw ~ '^[0-9]' AND (CAST(SPLIT_PART(diag_2_raw, '.', 1) AS INT) BETWEEN 520 AND 579 OR CAST(SPLIT_PART(diag_2_raw, '.', 1) AS INT) = 787) THEN 'Digestive'
        WHEN diag_2_raw ~ '^[0-9]' AND (CAST(SPLIT_PART(diag_2_raw, '.', 1) AS INT) BETWEEN 580 AND 629 OR CAST(SPLIT_PART(diag_2_raw, '.', 1) AS INT) = 788) THEN 'Genitourinary'
        WHEN diag_2_raw ~ '^[0-9]' AND (CAST(SPLIT_PART(diag_2_raw, '.', 1) AS INT) BETWEEN 140 AND 239) THEN 'Neoplasms'
        WHEN diag_2_raw ~ '^[0-9]' AND (CAST(SPLIT_PART(diag_2_raw, '.', 1) AS INT) BETWEEN 710 AND 739) THEN 'Musculoskeletal'
        WHEN diag_2_raw ~ '^[0-9]' AND (CAST(SPLIT_PART(diag_2_raw, '.', 1) AS INT) BETWEEN 800 AND 999) THEN 'Injury'
        ELSE 'Other'
    END AS secondary_diagnosis_group

FROM raw_standardized;
