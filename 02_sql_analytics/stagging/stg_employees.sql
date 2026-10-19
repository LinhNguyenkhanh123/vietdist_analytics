CREATE TABLE staging.stg_employees AS
SELECT
    -- Employee identifiers and descriptive attributes
    NULLIF(TRIM(employee_id), '') AS employee_id,
    NULLIF(TRIM(full_name), '') AS full_name,
    NULLIF(TRIM(gender), '') AS gender,

    -- Date fields
    CASE
        WHEN TRIM(date_of_birth) ~ '^\d{4}-\d{2}-\d{2}$'
        THEN TRIM(date_of_birth)::DATE
        ELSE NULL
    END AS date_of_birth,

    CASE
        WHEN TRIM(join_date) ~ '^\d{4}-\d{2}-\d{2}$'
        THEN TRIM(join_date)::DATE
        ELSE NULL
    END AS join_date,

    -- Job and organizational attributes
    NULLIF(TRIM(position), '') AS position,
    NULLIF(TRIM(region), '') AS region,
    NULLIF(TRIM(team), '') AS team,
    NULLIF(TRIM(email), '') AS email,
    NULLIF(TRIM(phone), '') AS phone,
    NULLIF(TRIM(status), '') AS status,

    -- Versioning / employee history
    NULLIF(TRIM(version), '') AS version,

    CASE
        WHEN TRIM(effective_date) ~ '^\d{4}-\d{2}-\d{2}$'
        THEN TRIM(effective_date)::DATE
        ELSE NULL
    END AS effective_date,

    CASE
        WHEN TRIM(resign_date) ~ '^\d{4}-\d{2}-\d{2}$'
        THEN TRIM(resign_date)::DATE
        ELSE NULL
    END AS resign_date,

    NULLIF(TRIM(transfer_note), '') AS transfer_note,

    -- Ingestion metadata
    _source_file,
    _source_platform,
    _ingested_at,
    _batch_id

FROM raw.employee_master;