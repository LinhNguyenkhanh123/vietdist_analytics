# Data Issues – Bronze Layer Profiling

## 1. Profiling Overview

This document records the initial data quality assessment of the Bronze Layer before transformations. It covers row counts, missing values and duplicate values in key columns across the 10 source tables.

This profiling does not yet cover all potential data quality dimensions, including invalid data types, malformed dates or outliers. The reported results should be treated as a baseline for subsequent Silver-layer cleaning and validation, rather than evidence that the source data is error-free.

## 2. Profiling Summary

| Table | Total rows | Null-check key | Null rate (%) | Duplicate-check key | Duplicate count
|---|---:|---|---:|---|---:|
| `raw.sales_transactions` | 119,101 | `order_id` | 0 | `order_id` | 35,090
| `raw.sales_target_raw` | 1,950 | `employee_id` | 0 | `target_file_id` + `source_row` | 0
| `raw.customer_master` | 2,000 | `customer_id` | 0 | `customer_id` | 0
| `raw.product_master` | 100 | `product_id` | 0 | `product_id` | 0
| `raw.distributor_orders` | 35,945 | `order_id` | 0 | `order_id` | 7,028
| `raw.distributor_master` | 138 | `distributor_id` | 0 | `distributor_id` | 0
| `raw.employee_master` | 114 | `employee_id` | 0 | `employee_id` + `version` + `effective_date` | 0
| `raw.territory_mapping` | 1,843 | `territory_id` | 0 | `territory_id` | 0
| `raw.return_transactions` | 3,665 | `return_id` | 0 | `return_id` | 0
| `raw.promotion_program` | 40 | `promotion_id` | 0 | `promotion_id` | 0

**Note:**  Null checks account for SQL `NULL`, empty strings and whitespace-only values where applicable.

## 3. Data Issues

### 3.1. Issue 1: Repeated values in transaction tables

**Observation:** The profiling queries reported 35,090 repeated-key records for `raw.sales_transactions` and 7,028 for `raw.distributor_orders` when checking `order_id`.

**Assessment:** Duplicates happen because an order can contain multiple products. Fow `raw.sales_transactions`, no duplicates were found using the combination of `order_id`, `product_id`, `quantity`, `unit_price`, `discount_pct`, and `net_amount`. For `raw.distributor_orders`, no duplicates were found using the combination of `order_id`, `product_id`, `distributor_id`, `qty_ordered`, `qty_delivered`, `distributor_price`, `gross_amount`, `delivered_amount`, `expected_delivery_date`, `actual_delivery_date`, and `delivery_status`.

**Planned Silver-layer handling:** Retain legitimate multiple-product lines belonging to the same order.


### 3.2. Issue 2: Limited null-check coverage

**Observation:** The reported null rate is 0% for the selected key column or columns in each table.

**Assessment:** These results confirm only that the checked columns had no detected null values. They do not establish that every column in every table is complete.

**Planned Silver-layer handling:** Expand null profiling to other required business columns.


### 3.3. Issue 3: Composite-key validation

**Affected tables:**
- `raw.sales_target_raw`
- `raw.employee_master`
- `raw.territory_mapping`
- `raw.sales_transactions`
- `raw.distributor_orders`

**Observation:** No duplicate groups were found for the composite keys or transaction-line combinations tested.

**Assessment:** This is a positive initial result for the selected combinations, but it does not prove that every record is unique under the correct business definition.

**Planned Silver-layer handling:** Validate composite-key columns for missing values and inconsistent formatting.