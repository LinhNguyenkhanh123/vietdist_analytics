
CREATE TABLE staging.stg_sales_targets_versioned AS
SELECT
    st.*,
    CASE
        -- v1 remains effective for January–June
        WHEN st.plan_version = 'v1'
             AND st.year = 2024
             AND st.month BETWEEN 1 AND 6
            THEN TRUE

        -- v2 replaces v1 for July–December
        WHEN st.plan_version = 'v2'
             AND st.year = 2024
             AND st.month BETWEEN 7 AND 12
            THEN TRUE

        -- Historical records that are no longer effective
        ELSE FALSE
    END AS is_latest
FROM staging.stg_sales_targets AS st;

--Testing--
SELECT
    plan_version,
    month,
    is_latest,
    COUNT(*) AS row_count,
    COUNT(DISTINCT employee_id) AS employee_count
FROM staging.stg_sales_targets_versioned
GROUP BY plan_version, month, is_latest
ORDER BY month, plan_version, is_latest;