INSERT INTO silver.fact_installment (
    ingested_at,
    updated_at,
    installment_schedule_id,
    agreement_id,
    installment_sequence_no,
    due_date,
    installment_amt,
    installment_paid_amt,
    installment_waived_amt,
    installment_paid_date,
    principal_amt,
    interest_amt
)
SELECT
    NOW() AS ingested_at,
    NOW() AS updated_at,
    inst_schdl_id AS installment_schedule_id,
    agrmnt_id AS agreement_id,
    inst_seq_no AS installment_sequence_no,
    due_dt AS due_date,
    inst_amt AS installment_amt,
    inst_paid_amt AS installment_paid_amt,
    inst_waived_amt AS installment_waived_amt,
    inst_paid_date AS installment_paid_date,
    principal_amt,
    interest_amt
FROM bronze.inst_schdl
ON CONFLICT (installment_schedule_id)
DO UPDATE SET
    agreement_id = EXCLUDED.agreement_id,
    installment_sequence_no = EXCLUDED.installment_sequence_no,
    due_date = EXCLUDED.due_date,
    installment_amt = EXCLUDED.installment_amt,
    installment_paid_amt = EXCLUDED.installment_paid_amt,
    installment_waived_amt = EXCLUDED.installment_waived_amt,
    installment_paid_date = EXCLUDED.installment_paid_date,
    principal_amt = EXCLUDED.principal_amt,
    interest_amt = EXCLUDED.interest_amt,
    updated_at = NOW();


