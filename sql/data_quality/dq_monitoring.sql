WITH checks AS (
 
-- ===== COMPLETENESS Bronze =====
SELECT 'bronze.cust' AS table_name, 'cust_id' AS column_name,
       'Completeness' AS dimension, 'Bronze' AS layer,
       'cust_id tidak NULL' AS rule_description,
       COUNT(*) AS total_rows,
       COUNT(*) FILTER (WHERE cust_id IS NULL) AS violation_count
FROM bronze.cust
UNION ALL
SELECT 'bronze.agrmnt', 'id, tanggal, amount', 'Completeness', 'Bronze',
       'id, semua tanggal, dan amount wajib tidak NULL',
       COUNT(*),
       COUNT(*) FILTER (WHERE agrmnt_id IS NULL OR next_inst_due_dt IS NULL
           OR next_inst_dt IS NULL OR agrmnt_dt IS NULL OR effective_dt IS NULL
           OR total_down_payment_nett_amt IS NULL OR inst_amt IS NULL)
FROM bronze.agrmnt
UNION ALL
SELECT 'bronze.inst_schdl', 'id, due_dt, amount', 'Completeness', 'Bronze',
       'id, due_dt, dan amount wajib tidak NULL',
       COUNT(*),
       COUNT(*) FILTER (WHERE inst_schdl_id IS NULL OR agrmnt_id IS NULL
           OR due_dt IS NULL OR inst_amt IS NULL OR principal_amt IS NULL
           OR interest_amt IS NULL)
FROM bronze.inst_schdl
UNION ALL
SELECT 'bronze.ref_office', 'ref_office, brnch_code, brnch_name', 'Completeness', 'Bronze',
       'ref_office, brnch_code, dan brnch_name wajib tidak NULL',
       COUNT(*),
       COUNT(*) FILTER (
           WHERE ref_office IS NULL
              OR brnch_code IS NULL
              OR brnch_name IS NULL
       )
FROM bronze.ref_office

-- ===== UNIQUENESS Bronze (before) =====
UNION ALL
SELECT 'bronze.cust', 'cust_id', 'Uniqueness', 'Bronze', 'cust_id unik (tidak duplikat)',
       COUNT(*),
       (SELECT COALESCE(SUM(c-1),0) FROM (
           SELECT COUNT(*) c FROM bronze.cust GROUP BY cust_id HAVING COUNT(*) > 1) d)
FROM bronze.cust
UNION ALL
SELECT 'bronze.agrmnt', 'agrmnt_id', 'Uniqueness', 'Bronze', 'agrmnt_id unik (tidak duplikat)',
       COUNT(*),
       (SELECT COALESCE(SUM(c-1),0) FROM (
           SELECT COUNT(*) c FROM bronze.agrmnt GROUP BY agrmnt_id HAVING COUNT(*) > 1) d)
FROM bronze.agrmnt
UNION ALL
SELECT 'bronze.inst_schdl', 'inst_schdl_id', 'Uniqueness', 'Bronze', 'inst_schdl_id unik (tidak duplikat)',
       COUNT(*),
       (SELECT COALESCE(SUM(c-1),0) FROM (
           SELECT COUNT(*) c FROM bronze.inst_schdl GROUP BY inst_schdl_id HAVING COUNT(*) > 1) d)
FROM bronze.inst_schdl
UNION ALL
SELECT 'bronze.ref_office', 'ref_office', 'Uniqueness', 'Bronze',
       'ref_office unik (tidak duplikat)',
       COUNT(*),
       (SELECT COALESCE(SUM(c - 1), 0)
        FROM (
            SELECT COUNT(*) AS c
            FROM bronze.ref_office
            GROUP BY ref_office
            HAVING COUNT(*) > 1
        ) d)
FROM bronze.ref_office

-- ===== COMPLETENESS Silver =====
UNION ALL
SELECT 'silver.dim_customer', 'customer_id', 'Completeness', 'Silver',
       'customer_id tidak NULL',
       COUNT(*), COUNT(*) FILTER (WHERE customer_id IS NULL)
FROM silver.dim_customer
UNION ALL
SELECT 'silver.fact_agreement', 'id, tanggal, amount', 'Completeness', 'Silver',
       'id, semua tanggal, dan amount wajib tidak NULL',
       COUNT(*),
       COUNT(*) FILTER (WHERE agreement_id IS NULL OR next_installment_due_date IS NULL
           OR next_installment_date IS NULL OR agreement_date IS NULL OR effective_date IS NULL
           OR total_down_payment_nett_amt IS NULL OR installment_amt IS NULL)
FROM silver.fact_agreement
UNION ALL
SELECT 'silver.fact_installment', 'id, due_date, amount', 'Completeness', 'Silver',
       'id, due_date, dan amount wajib tidak NULL',
       COUNT(*),
       COUNT(*) FILTER (WHERE installment_schedule_id IS NULL OR agreement_id IS NULL
           OR due_date IS NULL OR installment_amt IS NULL OR principal_amt IS NULL
           OR interest_amt IS NULL)
FROM silver.fact_installment
 
-- ===== UNIQUENESS Silver =====
UNION ALL
SELECT 'silver.dim_customer', 'customer_id', 'Uniqueness', 'Silver', 'customer_id unik (tidak duplikat)',
       COUNT(*),
       (SELECT COALESCE(SUM(c-1),0) FROM (
           SELECT COUNT(*) c FROM silver.dim_customer GROUP BY customer_id HAVING COUNT(*) > 1) d)
FROM silver.dim_customer
UNION ALL
SELECT 'silver.fact_agreement', 'agreement_id', 'Uniqueness', 'Silver', 'agreement_id unik (tidak duplikat)',
       COUNT(*),
       (SELECT COALESCE(SUM(c-1),0) FROM (
           SELECT COUNT(*) c FROM silver.fact_agreement GROUP BY agreement_id HAVING COUNT(*) > 1) d)
FROM silver.fact_agreement
UNION ALL
SELECT 'silver.fact_installment', 'installment_schedule_id', 'Uniqueness', 'Silver', 'installment_schedule_id unik (tidak duplikat)',
       COUNT(*),
       (SELECT COALESCE(SUM(c-1),0) FROM (
           SELECT COUNT(*) c FROM silver.fact_installment GROUP BY installment_schedule_id HAVING COUNT(*) > 1) d)
FROM silver.fact_installment
 
-- ===== CONSISTENCY before/after Bronze vs Silver =====
UNION ALL
SELECT 'bronze.cust', 'phone_number', 'Consistency', 'Bronze', 'phone_number diawali 62',
       COUNT(*), COUNT(*) FILTER (WHERE phone_number IS NOT NULL AND phone_number NOT LIKE '62%')
FROM bronze.cust
UNION ALL
SELECT 'silver.dim_customer', 'phone_number', 'Consistency', 'Silver', 'phone_number diawali 62',
       COUNT(*), COUNT(*) FILTER (WHERE phone_number IS NOT NULL AND phone_number NOT LIKE '62%')
FROM silver.dim_customer
UNION ALL
SELECT 'bronze.cust', 'gender', 'Consistency', 'Bronze', 'gender bernilai L atau P',
       COUNT(*), COUNT(*) FILTER (WHERE gender IS NOT NULL AND gender NOT IN ('L','P'))
FROM bronze.cust
UNION ALL
SELECT 'silver.dim_customer', 'gender', 'Consistency', 'Silver', 'gender bernilai L atau P',
       COUNT(*), COUNT(*) FILTER (WHERE gender IS NOT NULL AND gender NOT IN ('L','P'))
FROM silver.dim_customer
UNION ALL
SELECT 'bronze.cust', 'occupation', 'Consistency', 'Bronze', 'occupation sesuai bentuk baku',
       COUNT(*), COUNT(*) FILTER (WHERE occupation IS NOT NULL
           AND occupation NOT IN ('Karyawan Swasta','Ibu Rumah Tangga','Wiraswasta','PNS','Pegawai BUMN'))
FROM bronze.cust
UNION ALL
SELECT 'silver.dim_customer', 'occupation', 'Consistency', 'Silver', 'occupation sesuai bentuk baku',
       COUNT(*), COUNT(*) FILTER (WHERE occupation IS NOT NULL
           AND occupation NOT IN ('Karyawan Swasta','Ibu Rumah Tangga','Wiraswasta','PNS','Pegawai BUMN'))
FROM silver.dim_customer
 
-- ===== CONSISTENCY orphan Silver =====
UNION ALL
SELECT 'silver.fact_installment', 'agreement_id', 'Consistency', 'Silver', 'tidak ada orphan ke fact_agreement',
       (SELECT COUNT(*) FROM silver.fact_installment),
       (SELECT COUNT(*) FROM silver.fact_installment fi
        LEFT JOIN silver.fact_agreement fa ON fi.agreement_id = fa.agreement_id
        WHERE fa.agreement_id IS NULL)
UNION ALL
SELECT 'silver.fact_agreement', 'customer_id', 'Consistency', 'Silver', 'tidak ada orphan ke dim_customer',
       (SELECT COUNT(*) FROM silver.fact_agreement),
       (SELECT COUNT(*) FROM silver.fact_agreement fa
        LEFT JOIN silver.dim_customer dc ON fa.customer_id = dc.customer_id
        WHERE dc.customer_id IS NULL)
 
-- ===== VALIDITY Silver =====
UNION ALL
SELECT 'silver.fact_installment', 'installment_sequence_no', 'Validity', 'Silver', 'jumlah seq = max seq per agreement',
       (SELECT COUNT(DISTINCT agreement_id) FROM silver.fact_installment),
       (SELECT COUNT(*) FROM (
           SELECT agreement_id FROM silver.fact_installment
           GROUP BY agreement_id HAVING COUNT(installment_sequence_no) <> MAX(installment_sequence_no)
       ) x)
UNION ALL
SELECT 'silver.fact_installment', 'installment_amt', 'Validity', 'Silver', 'installment_amt <= paid + waived (angsuran dibayar)',
       (SELECT COUNT(*) FROM silver.fact_installment WHERE installment_paid_date IS NOT NULL),
       (SELECT COUNT(*) FROM silver.fact_installment
        WHERE installment_paid_date IS NOT NULL
          AND installment_amt > COALESCE(installment_paid_amt,0) + COALESCE(installment_waived_amt,0))
 
-- ===== ACCURACY Silver =====
UNION ALL
SELECT 'silver.fact_agreement', 'effective_date, agreement_date', 'Accuracy', 'Silver', 'effective_date >= agreement_date',
       COUNT(*), COUNT(*) FILTER (WHERE effective_date < agreement_date)
FROM silver.fact_agreement
UNION ALL
SELECT 'silver.fact_agreement', 'tenor', 'Accuracy', 'Silver', 'tenor = max seq no installment',
       (SELECT COUNT(*) FROM silver.fact_agreement fa
        JOIN (SELECT agreement_id, MAX(installment_sequence_no) AS max_seq
              FROM silver.fact_installment GROUP BY agreement_id) s ON fa.agreement_id = s.agreement_id),
       (SELECT COUNT(*) FROM silver.fact_agreement fa
        JOIN (SELECT agreement_id, MAX(installment_sequence_no) AS max_seq
              FROM silver.fact_installment GROUP BY agreement_id) s ON fa.agreement_id = s.agreement_id
        WHERE fa.tenor <> s.max_seq)
 
-- ===== GOLD: COMPLETENESS (11 kolom) =====
UNION ALL SELECT 'gold.dm_latecalculation','agreement_id','Completeness','Gold','agreement_id tidak NULL',
       COUNT(*), COUNT(*) FILTER (WHERE agreement_id IS NULL) FROM gold.dm_latecalculation
UNION ALL SELECT 'gold.dm_latecalculation','full_name','Completeness','Gold','full_name tidak NULL',
       COUNT(*), COUNT(*) FILTER (WHERE full_name IS NULL) FROM gold.dm_latecalculation
UNION ALL SELECT 'gold.dm_latecalculation','phone_number','Completeness','Gold','phone_number tidak NULL',
       COUNT(*), COUNT(*) FILTER (WHERE phone_number IS NULL) FROM gold.dm_latecalculation
UNION ALL SELECT 'gold.dm_latecalculation','address','Completeness','Gold','address tidak NULL',
       COUNT(*), COUNT(*) FILTER (WHERE address IS NULL) FROM gold.dm_latecalculation
UNION ALL SELECT 'gold.dm_latecalculation','branch_name','Completeness','Gold','branch_name tidak NULL',
       COUNT(*), COUNT(*) FILTER (WHERE branch_name IS NULL) FROM gold.dm_latecalculation
UNION ALL SELECT 'gold.dm_latecalculation','tenor','Completeness','Gold','tenor tidak NULL',
       COUNT(*), COUNT(*) FILTER (WHERE tenor IS NULL) FROM gold.dm_latecalculation
UNION ALL SELECT 'gold.dm_latecalculation','total_overdue_amt','Completeness','Gold','total_overdue_amt tidak NULL',
       COUNT(*), COUNT(*) FILTER (WHERE total_overdue_amt IS NULL) FROM gold.dm_latecalculation
UNION ALL SELECT 'gold.dm_latecalculation','days_past_due','Completeness','Gold','days_past_due tidak NULL',
       COUNT(*), COUNT(*) FILTER (WHERE days_past_due IS NULL) FROM gold.dm_latecalculation
UNION ALL SELECT 'gold.dm_latecalculation','overdue_installment_count','Completeness','Gold','overdue_installment_count tidak NULL',
       COUNT(*), COUNT(*) FILTER (WHERE overdue_installment_count IS NULL) FROM gold.dm_latecalculation
UNION ALL SELECT 'gold.dm_latecalculation','total_penalty_amt','Completeness','Gold','total_penalty_amt tidak NULL',
       COUNT(*), COUNT(*) FILTER (WHERE total_penalty_amt IS NULL) FROM gold.dm_latecalculation
UNION ALL SELECT 'gold.dm_latecalculation','ar_bucket','Completeness','Gold','ar_bucket tidak NULL',
       COUNT(*), COUNT(*) FILTER (WHERE ar_bucket IS NULL) FROM gold.dm_latecalculation
 
-- ===== GOLD: UNIQUENESS =====
UNION ALL
SELECT 'gold.dm_latecalculation','agreement_id','Uniqueness','Gold','agreement_id unik (tidak duplikat)',
       COUNT(*),
       (SELECT COALESCE(SUM(c-1),0) FROM (
           SELECT COUNT(*) c FROM gold.dm_latecalculation GROUP BY agreement_id HAVING COUNT(*) > 1) d)
FROM gold.dm_latecalculation
 
-- ===== GOLD: VALIDITY (6) =====
UNION ALL SELECT 'gold.dm_latecalculation','tenor','Validity','Gold','tenor > 0',
       COUNT(*), COUNT(*) FILTER (WHERE tenor <= 0) FROM gold.dm_latecalculation
UNION ALL SELECT 'gold.dm_latecalculation','days_past_due','Validity','Gold','days_past_due >= 0',
       COUNT(*), COUNT(*) FILTER (WHERE days_past_due < 0) FROM gold.dm_latecalculation
UNION ALL SELECT 'gold.dm_latecalculation','total_overdue_amt','Validity','Gold','total_overdue_amt >= 0',
       COUNT(*), COUNT(*) FILTER (WHERE total_overdue_amt < 0) FROM gold.dm_latecalculation
UNION ALL SELECT 'gold.dm_latecalculation','overdue_installment_count','Validity','Gold','overdue_installment_count >= 0',
       COUNT(*), COUNT(*) FILTER (WHERE overdue_installment_count < 0) FROM gold.dm_latecalculation
UNION ALL SELECT 'gold.dm_latecalculation','total_penalty_amt','Validity','Gold','total_penalty_amt >= 0',
       COUNT(*), COUNT(*) FILTER (WHERE total_penalty_amt < 0) FROM gold.dm_latecalculation
UNION ALL SELECT 'gold.dm_latecalculation','ar_bucket','Validity','Gold','ar_bucket termasuk kategori sah',
       COUNT(*), COUNT(*) FILTER (WHERE ar_bucket NOT IN
         ('current','01. 1 - 30 DPD','02. 31 - 60 DPD','03. 61 - 90 DPD','04. > 90 DPD (NPL)'))
FROM gold.dm_latecalculation
 
-- ===== GOLD: CONSISTENCY (3) =====
UNION ALL
SELECT 'gold.dm_latecalculation','phone_number','Consistency','Gold','phone_number diawali 62',
       COUNT(*), COUNT(*) FILTER (WHERE phone_number IS NOT NULL AND phone_number NOT LIKE '62%')
FROM gold.dm_latecalculation
UNION ALL
SELECT 'gold.dm_latecalculation','branch_name','Consistency','Gold','branch_name konsisten dengan referensi kantor (ref_office)',
       (SELECT COUNT(*) FROM gold.dm_latecalculation),
       (SELECT COUNT(*) FROM gold.dm_latecalculation g
        JOIN silver.fact_agreement fa ON g.agreement_id = fa.agreement_id
        LEFT JOIN bronze.ref_office ro ON fa.ref_office_id = ro.ref_office_id
        WHERE ro.ref_office_id IS NULL)
UNION ALL
SELECT 'gold.dm_latecalculation','agreement_id','Consistency','Gold','agreement_id tidak orphan ke fact_agreement',
       (SELECT COUNT(*) FROM gold.dm_latecalculation),
       (SELECT COUNT(*) FROM gold.dm_latecalculation g
        LEFT JOIN silver.fact_agreement fa ON g.agreement_id = fa.agreement_id
        WHERE fa.agreement_id IS NULL)
 
-- ===== GOLD: ACCURACY (3) =====
UNION ALL
SELECT 'gold.dm_latecalculation','days_past_due, ar_bucket','Accuracy','Gold','days_past_due sesuai kategori ar_bucket',
       COUNT(*),
       COUNT(*) FILTER (WHERE NOT (
              (days_past_due BETWEEN 1 AND 30  AND ar_bucket = '01. 1 - 30 DPD')
           OR (days_past_due BETWEEN 31 AND 60 AND ar_bucket = '02. 31 - 60 DPD')
           OR (days_past_due BETWEEN 61 AND 90 AND ar_bucket = '03. 61 - 90 DPD')
           OR (days_past_due > 90             AND ar_bucket = '04. > 90 DPD (NPL)')
           OR (days_past_due < 1              AND ar_bucket = 'current')))
FROM gold.dm_latecalculation
UNION ALL
SELECT 'gold.dm_latecalculation','overdue_installment_count, total_overdue_amt','Accuracy','Gold','count=0 jika dan hanya jika amount=0',
       COUNT(*), COUNT(*) FILTER (WHERE (overdue_installment_count = 0) <> (total_overdue_amt = 0))
FROM gold.dm_latecalculation
UNION ALL
SELECT 'gold.dm_latecalculation','total_overdue_amt, days_past_due','Accuracy','Gold','jika total_overdue_amt > 0 maka days_past_due > 0',
       COUNT(*), COUNT(*) FILTER (WHERE total_overdue_amt > 0 AND days_past_due < 1)
FROM gold.dm_latecalculation
 
)
INSERT INTO gold.dq_monitoring
    (run_timestamp, table_name, column_name, dimension, layer,
     rule_description, total_rows, violation_count, quality_percentage, status)
SELECT
    NOW() AS run_timestamp,
    table_name, column_name, dimension, layer, rule_description,
    total_rows, violation_count,
    ROUND((total_rows - violation_count)::NUMERIC / NULLIF(total_rows,0) * 100, 2) AS quality_percentage,
    CASE WHEN violation_count = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM checks;