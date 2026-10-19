CREATE TABLE staging.stg_distributors AS
WITH cleaned AS (
    SELECT
        NULLIF(TRIM(distributor_id), '') AS distributor_id,
        NULLIF(TRIM(distributor_name), '') AS distributor_name,
        NULLIF(TRIM(tier), '') AS tier,
        NULLIF(TRIM(channel), '') AS channel,
        NULLIF(TRIM(province), '') AS province,
        NULLIF(TRIM(region), '') AS region,
        NULLIF(TRIM(contact_person), '') AS contact_person,
        NULLIF(TRIM(phone), '') AS phone,
        NULLIF(TRIM(email), '') AS email,
        NULLIF(TRIM(tax_code), '') AS tax_code,
        NULLIF(TRIM(join_date), '') AS join_date_raw,
        NULLIF(TRIM(credit_limit), '') AS credit_limit_raw,
        NULLIF(TRIM(status), '') AS status,
        NULLIF(TRIM(assigned_supervisor_id), '') AS assigned_supervisor_id,
        _source_file,
        _source_platform,
        _ingested_at,
        _batch_id
    FROM raw.distributor_master
)
SELECT
    distributor_id,
    distributor_name,
    tier,
    channel,
    province,
    region,
    contact_person,
    phone,
    email,
    tax_code,
    CASE
        WHEN join_date_raw ~ '^\d{4}-\d{2}-\d{2}$'
        THEN join_date_raw::DATE
        ELSE NULL
    END AS join_date,
    CASE
        WHEN credit_limit_raw ~ '^[+-]?\d+(\.\d+)?$'
        THEN credit_limit_raw::NUMERIC
        ELSE NULL
    END AS credit_limit,
    status,
    assigned_supervisor_id,
    _source_file,
    _source_platform,
    _ingested_at,
    _batch_id
FROM cleaned;

--1. Row count comparison between raw and staging tables
SELECT 'distributors' AS table_name,
       (SELECT COUNT(*) FROM raw.distributor_master) AS bronze_rows,
       (SELECT COUNT(*) FROM staging.stg_distributors) AS silver_rows

--2. Null-check
SELECT
    'stg_distributors' AS table_name,
    COUNT(*) FILTER (WHERE join_date IS NULL) AS null_dates,
    COUNT(*) FILTER (WHERE credit_limit IS NULL) AS null_numbers
FROM staging.stg_distributors