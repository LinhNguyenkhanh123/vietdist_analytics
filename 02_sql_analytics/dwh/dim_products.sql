CREATE TABLE dwh.dim_products (
    product_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id TEXT NOT NULL UNIQUE,
    product_name TEXT,
    category TEXT,
    sub_category TEXT,
    unit TEXT,
    unit_price NUMERIC,
    cost_price NUMERIC,
    weight_gram NUMERIC,
    status TEXT,
    launch_date DATE
);

-- Load data from Silver
INSERT INTO dwh.dim_products (
    product_id,
    product_name,
    category,
    sub_category,
    unit,
    unit_price,
    cost_price,
    weight_gram,
    status,
    launch_date
)
SELECT
    TRIM(product_id),
    NULLIF(TRIM(product_name), ''),
    NULLIF(TRIM(category), ''),
    NULLIF(TRIM(sub_category), ''),
    NULLIF(TRIM(unit), ''),
    unit_price,
    cost_price,
    weight_gram,
    NULLIF(TRIM(status), ''),
    launch_date
FROM staging.stg_products;