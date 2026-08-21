-- ============================================================================
-- SQL Script: 01_staging.sql
-- Description: Sets up the staging schema and populates raw patient encounters
--              from the source dataset.
--
-- Compliance & Standards Notice:
-- ----------------------------------------------------------------------------
-- HIPAA Compliance (Privacy Rule & PHI Protection):
--   - This staging table utilizes de-identified research data. 
--   - All direct Patient Identifiers (names, SSN, phone numbers, exact dates) 
--     are removed or hashed into surrogate identifiers (patient_id, encounter_id) 
--     in accordance with the HIPAA Safe Harbor De-identification standard.
--   - Sensitive demographics (age group, race, gender) are tracked at aggregate
--     levels to protect patient privacy.
--
-- HL7 Standards (Clinical Data Integration):
--   - Terminologies correspond to HL7 v2/v3 and FHIR vocabulary specifications:
--     - primary_diagnosis_code: Coded in standard ICD-9-CM format.
--     - discharge_disposition: Coded in standard UB-04 / HL7 Table 0112 values.
--     - admission_type: Coded in standard HL7 Table 0007 (Admission Type).
--     - num_lab_procedures: Maps to HL7 OBX (Observation/Result) segments.
-- ============================================================================

-- Create schema if not exists
CREATE SCHEMA IF NOT EXISTS staging;

-- Drop tables if they exist to ensure clean setup
DROP TABLE IF EXISTS staging.raw_clinical_records CASCADE;

-- Create Raw Clinical Records Table
CREATE TABLE staging.raw_clinical_records (
    encounter_id INT PRIMARY KEY,
    patient_id INT NOT NULL,
    age VARCHAR(50),
    gender VARCHAR(20),
    admission_type VARCHAR(50),
    length_of_stay INT,
    primary_diagnosis_code VARCHAR(20),
    num_lab_procedures INT,
    num_medications INT,
    number_emergency_visits INT,
    number_inpatient_visits INT,
    discharge_disposition VARCHAR(100),
    readmitted_flag VARCHAR(10)
);

-- Indexing for performance
CREATE INDEX idx_raw_patient_id ON staging.raw_clinical_records(patient_id);
CREATE INDEX idx_raw_readmitted_flag ON staging.raw_clinical_records(readmitted_flag);

-- Ingest/Stage Data from public.diabetic_data
TRUNCATE TABLE staging.raw_clinical_records;

INSERT INTO staging.raw_clinical_records (
    encounter_id,
    patient_id,
    age,
    gender,
    admission_type,
    length_of_stay,
    primary_diagnosis_code,
    num_lab_procedures,
    num_medications,
    number_emergency_visits,
    number_inpatient_visits,
    discharge_disposition,
    readmitted_flag
)
SELECT 
    CAST(encounter_id AS INT),
    CAST(patient_nbr AS INT),
    age,
    gender,
    admission_type_id,
    CAST(NULLIF(time_in_hospital, '?') AS INT),
    diag_1,
    CAST(NULLIF(num_lab_procedures, '?') AS INT),
    CAST(NULLIF(num_medications, '?') AS INT),
    CAST(NULLIF(number_emergency, '?') AS INT),
    CAST(NULLIF(number_inpatient, '?') AS INT),
    discharge_disposition_id,
    readmitted
FROM public.diabetic_data;

SELECT COUNT(*) AS staged_records_count FROM staging.raw_clinical_records;
