CREATE TABLE dwh.fact_targets (
    target_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    employee_key BIGINT NOT NULL,
    target_month DATE NOT NULL,

    plan_version TEXT NOT NULL,
    version_date DATE,
    effective_from DATE NOT NULL,
    effective_to DATE NOT NULL,
    is_latest BOOLEAN NOT NULL,

    target_revenue NUMERIC,
    target_quantity NUMERIC,
    target_new_customers NUMERIC,

    CONSTRAINT fk_fact_targets_employee
        FOREIGN KEY (employee_key)
        REFERENCES dwh.dim_employees(employee_key),

    CONSTRAINT uq_fact_targets_version
        UNIQUE (employee_key, target_month, plan_version)
);

-- Load target versions
INSERT INTO dwh.fact_targets (
    employee_key,
    target_month,
    plan_version,
    version_date,
    effective_from,
    effective_to,
    is_latest,
    target_revenue,
    target_quantity,
    target_new_customers
)
SELECT
    e.employee_key,
    MAKE_DATE(t.year, t.month, 1) AS target_month,
    t.plan_version,
    t.version_date,
    t.effective_from,
    t.effective_to,
    t.is_latest,
    t.target_revenue,
    t.target_quantity,
    t.target_new_customers
FROM staging.stg_sales_targets_versioned t
JOIN dwh.dim_employees e
    ON TRIM(t.employee_id) = e.employee_id
   AND MAKE_DATE(t.year, t.month, 1)
       BETWEEN e.effective_from AND e.effective_to;