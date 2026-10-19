CREATE TABLE dwh.dim_customers (
    customer_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id TEXT NOT NULL UNIQUE,
    customer_name TEXT,
    customer_type TEXT,
    channel TEXT,
    province TEXT,
    region TEXT,
    address TEXT,
    phone TEXT,
    tax_code TEXT,
    join_date DATE,
    credit_limit NUMERIC,
    status TEXT
);

-- Load customer data from Silver
INSERT INTO dwh.dim_customers (
    customer_id,
    customer_name,
    customer_type,
    channel,
    province,
    region,
    address,
    phone,
    tax_code,
    join_date,
    credit_limit,
    status
)
SELECT
    TRIM(customer_id),
    NULLIF(TRIM(customer_name), ''),
    NULLIF(TRIM(customer_type), ''),
    NULLIF(TRIM(channel), ''),
    NULLIF(TRIM(province), ''),
    NULLIF(TRIM(region), ''),
    NULLIF(TRIM(address), ''),
    NULLIF(TRIM(phone), ''),
    NULLIF(TRIM(tax_code), ''),
    join_date,
    credit_limit,
    NULLIF(TRIM(status), '')
FROM staging.stg_customers;