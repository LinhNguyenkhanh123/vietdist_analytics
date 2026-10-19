CREATE TABLE dwh.dim_distributors (
    distributor_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    distributor_id TEXT NOT NULL,
    distributor_name TEXT,
    tier TEXT,
    channel TEXT,
    province TEXT,
    region TEXT,
    contact_person TEXT,
    phone TEXT,
    email TEXT,
    tax_code TEXT,
    join_date DATE,
    credit_limit NUMERIC,
    status TEXT,
    assigned_supervisor_id TEXT,
    effective_from DATE NOT NULL,
    effective_to DATE NOT NULL,
    is_current BOOLEAN NOT NULL,

    CONSTRAINT chk_distributor_effective_dates
        CHECK (effective_from <= effective_to)
);

--one current version per distributor
CREATE UNIQUE INDEX uq_dim_distributors_current
    ON dwh.dim_distributors (distributor_id)
    WHERE is_current = TRUE;

-- Initial load: one current version per distributor
INSERT INTO dwh.dim_distributors (
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
    join_date,
    credit_limit,
    status,
    assigned_supervisor_id,
    effective_from,
    effective_to,
    is_current
)
SELECT
    TRIM(distributor_id),
    NULLIF(TRIM(distributor_name), ''),
    NULLIF(TRIM(tier), ''),
    NULLIF(TRIM(channel), ''),
    NULLIF(TRIM(province), ''),
    NULLIF(TRIM(region), ''),
    NULLIF(TRIM(contact_person), ''),
    NULLIF(TRIM(phone), ''),
    NULLIF(TRIM(email), ''),
    NULLIF(TRIM(tax_code), ''),
    join_date,
    credit_limit,
    NULLIF(TRIM(status), ''),
    NULLIF(TRIM(assigned_supervisor_id), ''),
    DATE '1900-01-01',
    DATE '9999-12-31',
    TRUE
FROM staging.stg_distributors;