INSERT INTO silver.dim_customer (
    ingested_at,
    updated_at,
    customer_id,
    full_name,
    gender,
    phone_number,
    personal_id,
    npwp,
    spouse_id,
    address,
    occupation
)
SELECT
    NOW() AS ingested_at,
    NOW() AS updated_at,
    NULLIF(cust_id, '')::BIGINT AS customer_id,
    INITCAP(TRIM(full_name)) AS full_name,
    CASE
        WHEN UPPER(TRIM(gender)) IN ('L','LAKI-LAKI','LAKI LAKI','PRIA','M','MALE') THEN 'L'
        WHEN UPPER(TRIM(gender)) IN ('P','PEREMPUAN','WANITA','F','FEMALE') THEN 'P'
						        ELSE NULL
    END AS gender,
    CASE
        WHEN phone_number LIKE '62%' THEN phone_number
        WHEN phone_number LIKE '0%'  THEN '62' || SUBSTRING(phone_number FROM 2)
        WHEN phone_number LIKE '8%'  THEN '62' || phone_number
        ELSE phone_number
    END AS phone_number,
    personal_id,
    npwp,
    NULLIF(spouse_id, '')::BIGINT AS spouse_id,
    REGEXP_REPLACE(
      REGEXP_REPLACE(
        REGEXP_REPLACE(
          REGEXP_REPLACE(
            REGEXP_REPLACE(
              REGEXP_REPLACE(
                REGEXP_REPLACE(
                  REGEXP_REPLACE(
                    REGEXP_REPLACE(
                      REGEXP_REPLACE(
                        REGEXP_REPLACE(
                          INITCAP(TRIM(REGEXP_REPLACE(address, '\s+', ' ', 'g'))),
                        '\mDki\M', 'DKI', 'g'),
                      '\mRt\M', 'RT', 'g'),
                    '\mRw\M', 'RW', 'g'),
                  '\mJalan\M', 'Jl.', 'g'),
                '\mJl\M\.?', 'Jl.', 'g'),
              '\mNomor\M', 'No.', 'g'),
            '\mNo\M\.?', 'No.', 'g'),
          '\mKelurahan\M', 'Kel.', 'g'),
        '\mKel\M\.?', 'Kel.', 'g'),
      '\mKecamatan\M', 'Kec.', 'g'),
    '\mKec\M\.?', 'Kec.', 'g') AS address,
    CASE UPPER(TRIM(occupation))
        WHEN 'KARYAWAN SWASTA'  THEN 'Karyawan Swasta'
        WHEN 'IBU RUMAH TANGGA'  THEN 'Ibu Rumah Tangga'
        WHEN 'WIRASWASTA'        THEN 'Wiraswasta'
        WHEN 'PNS'               THEN 'PNS'
        WHEN 'PEGAWAI BUMN'      THEN 'Pegawai BUMN'
        ELSE INITCAP(TRIM(occupation))
    END AS occupation
FROM bronze.cust
ON CONFLICT (customer_id)
DO UPDATE SET
    full_name    = EXCLUDED.full_name,
    gender       = EXCLUDED.gender,
    phone_number = EXCLUDED.phone_number,
    personal_id  = EXCLUDED.personal_id,
    npwp         = EXCLUDED.npwp,
    spouse_id    = EXCLUDED.spouse_id,
    address      = EXCLUDED.address,
    occupation   = EXCLUDED.occupation,
    updated_at   = NOW();
