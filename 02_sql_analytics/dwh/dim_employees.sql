CREATE TABLE dwh.dim_employees (
    employee_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id TEXT NOT NULL,
    full_name TEXT,
    gender TEXT,
    date_of_birth DATE,
    join_date DATE,
    position TEXT,
    region TEXT,
    team TEXT,
    email TEXT,
    phone TEXT,
    status TEXT,
    effective_from DATE NOT NULL,
    effective_to DATE NOT NULL,
    is_current BOOLEAN NOT NULL,
    CONSTRAINT uq_dim_employees_version
        UNIQUE (employee_id, effective_from),
    CONSTRAINT chk_employee_effective_dates
        CHECK (effective_from <= effective_to)
);


-- Nạp dữ liệu vào dim_employees
WITH target_v2 AS (
    SELECT
        employee_id,
        MIN(region) AS region,
        MIN(team) AS team
    FROM staging.stg_sales_targets
    WHERE plan_version = 'v2'
      AND month BETWEEN 7 AND 12
    GROUP BY employee_id
    HAVING COUNT(DISTINCT region) = 1
       AND COUNT(DISTINCT team) = 1
),
employee_versions AS (
    -- 5 nhân viên chuyển vùng
    SELECT
        e.employee_id,
        e.full_name,
        e.gender,
        e.date_of_birth,
        e.join_date,
        e.position,
        e.region,
        e.team,
        e.email,
        e.phone,
        e.status,
        e.effective_date AS effective_from,
        DATE '2024-06-30' AS effective_to,
        FALSE AS is_current
    FROM staging.stg_employees e
    JOIN target_v2 t
      ON e.employee_id = t.employee_id
    WHERE (
        e.region IS DISTINCT FROM t.region
        OR e.team IS DISTINCT FROM t.team
    )
      AND e.effective_date <= DATE '2024-06-30'

    UNION ALL

    -- Ver mới nhất của toàn bộ nhân viên
    SELECT
        e.employee_id,
        e.full_name,
        e.gender,
        e.date_of_birth,
        e.join_date,
        e.position,
        COALESCE(t.region, e.region) AS region,
        COALESCE(t.team, e.team) AS team,
        e.email,
        e.phone,
        e.status,
        CASE
            WHEN t.employee_id IS NOT NULL
             AND (
                 e.region IS DISTINCT FROM t.region
                 OR e.team IS DISTINCT FROM t.team
             )
            THEN DATE '2024-07-01'
            ELSE e.effective_date
        END AS effective_from,
        DATE '9999-12-31' AS effective_to,
        TRUE AS is_current
    FROM staging.stg_employees e
    LEFT JOIN target_v2 t
      ON e.employee_id = t.employee_id
)
INSERT INTO dwh.dim_employees (
    employee_id,
    full_name,
    gender,
    date_of_birth,
    join_date,
    position,
    region,
    team,
    email,
    phone,
    status,
    effective_from,
    effective_to,
    is_current
)
SELECT
    employee_id,
    full_name,
    gender,
    date_of_birth,
    join_date,
    position,
    region,
    team,
    email,
    phone,
    status,
    effective_from,
    effective_to,
    is_current
FROM employee_versions;