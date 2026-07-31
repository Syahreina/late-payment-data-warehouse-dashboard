INSERT INTO gold.dm_latecalculation (
    ingested_at, updated_at, agreement_id, date, full_name, phone_number,
    address, branch_name, product_type, tenor, total_overdue_amt, days_past_due,
    overdue_installment_count, total_penalty_amt, ar_bucket
)

WITH date as (select cut_off as date from gold.cut_off)

,ins AS (
    SELECT
        agreement_id,
        due_date,
        installment_amt,
        (date::DATE - due_date::DATE) AS days_past_due,
        (
            ((date::DATE - due_date::DATE) / 30) * 75000
        )
        +
        CASE
            WHEN (((date::DATE - due_date::DATE) % 30) * installment_amt * 0.05) > 75000
                THEN 75000
            ELSE (((date::DATE - due_date::DATE) % 30) * installment_amt * 0.05)
        END AS penalty_amount
    FROM silver.fact_installment
    CROSS JOIN date
    WHERE due_date < date::DATE
        AND installment_paid_date IS NULL
),
value AS (
    SELECT
        i.agreement_id,
        SUM(i.installment_amt)  AS total_overdue_amt,
        MAX(i.days_past_due)    AS days_past_due,
        COUNT(i.agreement_id)   AS overdue_installment_count,
        SUM(i.penalty_amount)   AS total_penalty_amt
    FROM ins i
    GROUP BY i.agreement_id
)
SELECT
    NOW(),
    NOW(),
    a.agreement_id,
    d.date::DATE AS date,
    dc.full_name,
    dc.phone_number,
    dc.address,
    ro.brnch_name AS branch_name,
    a.product_type,
    a.tenor,
    COALESCE(v.total_overdue_amt, 0),
    COALESCE(v.days_past_due, 0),
    COALESCE(v.overdue_installment_count, 0),
    COALESCE(v.total_penalty_amt, 0),
    CASE
        WHEN v.days_past_due BETWEEN 1  AND 30 THEN '01. 1 - 30 DPD'
        WHEN v.days_past_due BETWEEN 31 AND 60 THEN '02. 31 - 60 DPD'
        WHEN v.days_past_due BETWEEN 61 AND 90 THEN '03. 61 - 90 DPD'
        WHEN v.days_past_due > 90              THEN '04. > 90 DPD (NPL)'
        ELSE 'current'
    END AS ar_bucket
FROM silver.fact_agreement a
CROSS JOIN date d
LEFT JOIN value v
    ON a.agreement_id = v.agreement_id
LEFT JOIN silver.dim_customer dc
    ON a.customer_id = dc.customer_id
LEFT JOIN bronze.ref_office ro
    ON a.ref_office_id = ro.ref_office_id
ON CONFLICT (agreement_id, date)
DO UPDATE SET
    full_name                 = EXCLUDED.full_name,
    phone_number              = EXCLUDED.phone_number,
    address                   = EXCLUDED.address,
    branch_name               = EXCLUDED.branch_name,
    product_type              = EXCLUDED.product_type,
    tenor                     = EXCLUDED.tenor,
    total_overdue_amt         = EXCLUDED.total_overdue_amt,
    days_past_due             = EXCLUDED.days_past_due,
    overdue_installment_count = EXCLUDED.overdue_installment_count,
    total_penalty_amt         = EXCLUDED.total_penalty_amt,
    ar_bucket                 = EXCLUDED.ar_bucket,
    updated_at                = NOW();