-- Bronze Layer DDL
-- Stores raw data copied from the source system without transformation.

CREATE SCHEMA IF NOT EXISTS bronze;

CREATE TABLE IF NOT EXISTS bronze.cust (
    cust_id VARCHAR,
    full_name VARCHAR,
    gender VARCHAR,
    phone_number VARCHAR,
    personal_id VARCHAR,
    npwp VARCHAR,
    spouse_id VARCHAR,
    address VARCHAR,
    occupation VARCHAR
);

CREATE TABLE IF NOT EXISTS bronze.agrmnt (
    agrmnt_id BIGINT,
    ref_curr_id VARCHAR(5),
    ref_office_id BIGINT,
    cust_id BIGINT,
    spouse_id BIGINT,
    tenor INTEGER,
    num_of_inst INTEGER,
    next_inst_due_num INTEGER,
    next_inst_num INTEGER,
    next_inst_due_dt TIMESTAMP,
    next_inst_dt TIMESTAMP,
    agrmnt_dt TIMESTAMP,
    effective_dt TIMESTAMP,
    total_down_payment_nett_amt NUMERIC,
    inst_amt NUMERIC,
    prod_type VARCHAR
);

CREATE TABLE IF NOT EXISTS bronze.inst_schdl (
    inst_schdl_id BIGINT,
    agrmnt_id BIGINT,
    inst_seq_no INTEGER,
    due_dt TIMESTAMP,
    inst_amt NUMERIC,
    inst_paid_amt NUMERIC,
    inst_waived_amt NUMERIC,
    inst_paid_dt TIMESTAMP,
    principal_amt NUMERIC,
    interest_amt NUMERIC
);

CREATE TABLE IF NOT EXISTS bronze.ref_office (
    ref_office_id INTEGER,
    brnch_name VARCHAR(50),
    brnch_code VARCHAR(50),
    reg_name VARCHAR(50),
    reg_code VARCHAR(50)
);
