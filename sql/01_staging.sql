-- ============================================================================
-- SQL Script: 01_staging.sql
-- Description: Sets up the staging tables to ingest raw clinical records
-- Target Dialect: PostgreSQL / standard ANSI SQL
-- ============================================================================

-- Create schema if not exists
CREATE SCHEMA IF NOT EXISTS staging;

-- Drop tables if they exist to ensure clean setup
DROP TABLE IF EXISTS staging.raw_clinical_records;

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
