-- ============================================================
-- SCRIPT : data_quality_tests.sql
-- PURPOSE: Data Quality Tests — Bronze, Silver, Gold layers
-- Notes  : Run after the full pipeline completes.
--          Each test either returns 0 (PASS) or >0 (FAIL).
--          A result of 0 = clean. Anything else needs attention.
-- ============================================================

USE datawarehouse;


-- ============================================================
-- BRONZE LAYER TESTS
-- Goal: confirm raw data loaded correctly from CSV files.
-- We are not validating values here — just volume and presence.
-- ============================================================

-- TEST B1: All bronze tables have rows (none empty)
SELECT 'B1 - bronze_customers not empty'   AS test, COUNT(*) AS result FROM bronze_customers
UNION ALL
SELECT 'B1 - bronze_sales not empty',               COUNT(*) FROM bronze_sales
UNION ALL
SELECT 'B1 - bronze_sales_items not empty',          COUNT(*) FROM bronze_sales_items
UNION ALL
SELECT 'B1 - bronze_products not empty',             COUNT(*) FROM bronze_products
UNION ALL
SELECT 'B1 - bronze_stock not empty',                COUNT(*) FROM bronze_stock
UNION ALL
SELECT 'B1 - bronze_channels not empty',             COUNT(*) FROM bronze_channels
UNION ALL
SELECT 'B1 - bronze_campaigns not empty',            COUNT(*) FROM bronze_campaigns;
-- Expected: all values > 0


-- TEST B2: No completely empty rows in bronze_sales
-- (sale_id is the anchor — if it's null, the row is garbage)
SELECT
    'B2 - bronze_sales null sale_id' AS test,
    COUNT(*) AS result
FROM bronze_sales
WHERE sale_id IS NULL OR TRIM(sale_id) = '';
-- Expected: 0


-- TEST B3: No completely empty rows in bronze_customers
SELECT
    'B3 - bronze_customers null customer_id' AS test,
    COUNT(*) AS result
FROM bronze_customers
WHERE customer_id IS NULL OR TRIM(customer_id) = '';
-- Expected: 0


-- TEST B4: No completely empty rows in bronze_sales_items
SELECT
    'B4 - bronze_sales_items null item_id' AS test,
    COUNT(*) AS result
FROM bronze_sales_items
WHERE item_id IS NULL OR TRIM(item_id) = '';
-- Expected: 0


-- ============================================================
-- SILVER LAYER TESTS
-- Goal: confirm transformations worked correctly.
-- Values should now be clean, cast, and standardized.
-- ============================================================

-- TEST S1: No duplicate customer IDs
SELECT
    'S1 - silver_customers duplicate customer_id' AS test,
    COUNT(*) AS result
FROM (
    SELECT customer_id, COUNT(*) AS cnt
    FROM silver_customers
    GROUP BY customer_id
    HAVING cnt > 1
) t;
-- Expected: 0


-- TEST S2: No duplicate sale IDs
SELECT
    'S2 - silver_sales duplicate sale_id' AS test,
    COUNT(*) AS result
FROM (
    SELECT sale_id, COUNT(*) AS cnt
    FROM silver_sales
    GROUP BY sale_id
    HAVING cnt > 1
) t;
-- Expected: 0


-- TEST S3: No duplicate item IDs in sales items
SELECT
    'S3 - silver_sales_items duplicate item_id' AS test,
    COUNT(*) AS result
FROM (
    SELECT item_id, COUNT(*) AS cnt
    FROM silver_sales_items
    GROUP BY item_id
    HAVING cnt > 1
) t;
-- Expected: 0


-- TEST S4: No duplicate product IDs
SELECT
    'S4 - silver_products duplicate product_id' AS test,
    COUNT(*) AS result
FROM (
    SELECT product_id, COUNT(*) AS cnt
    FROM silver_products
    GROUP BY product_id
    HAVING cnt > 1
) t;
-- Expected: 0


-- TEST S5: No negative or zero total_amount in sales
SELECT
    'S5 - silver_sales invalid total_amount' AS test,
    COUNT(*) AS result
FROM silver_sales
WHERE total_amount <= 0;
-- Expected: 0


-- TEST S6: No negative quantity in sales items
SELECT
    'S6 - silver_sales_items negative quantity' AS test,
    COUNT(*) AS result
FROM silver_sales_items
WHERE quantity < 0;
-- Expected: 0


-- TEST S7: No nulls on required fields in silver_sales
SELECT
    'S7 - silver_sales null sale_id'      AS test, COUNT(*) FROM silver_sales WHERE sale_id IS NULL
UNION ALL
SELECT 'S7 - silver_sales null channel',             COUNT(*) FROM silver_sales WHERE channel IS NULL
UNION ALL
SELECT 'S7 - silver_sales null total_amount',        COUNT(*) FROM silver_sales WHERE total_amount IS NULL
UNION ALL
SELECT 'S7 - silver_sales null sale_date',           COUNT(*) FROM silver_sales WHERE sale_date IS NULL
UNION ALL
SELECT 'S7 - silver_sales null customer_id',         COUNT(*) FROM silver_sales WHERE customer_id IS NULL;
-- Expected: all 0


-- TEST S8: No nulls on required fields in silver_customers
SELECT
    'S8 - silver_customers null customer_id' AS test, COUNT(*) FROM silver_customers WHERE customer_id IS NULL
UNION ALL
SELECT 'S8 - silver_customers null country',          COUNT(*) FROM silver_customers WHERE country IS NULL
UNION ALL
SELECT 'S8 - silver_customers null age_range',        COUNT(*) FROM silver_customers WHERE age_range IS NULL;
-- Expected: all 0


-- TEST S9: No nulls on required fields in silver_products
SELECT
    'S9 - silver_products null product_id'    AS test, COUNT(*) FROM silver_products WHERE product_id IS NULL
UNION ALL
SELECT 'S9 - silver_products null product_name',       COUNT(*) FROM silver_products WHERE product_name IS NULL
UNION ALL
SELECT 'S9 - silver_products null catalog_price',      COUNT(*) FROM silver_products WHERE catalog_price IS NULL
UNION ALL
SELECT 'S9 - silver_products null cost_price',         COUNT(*) FROM silver_products WHERE cost_price IS NULL;
-- Expected: all 0


-- TEST S10: Country values are standardized (no leftover abbreviations)
SELECT
    'S10 - silver_sales unexpected country' AS test,
    COUNT(*) AS result
FROM silver_sales
WHERE country NOT IN ('France', 'Germany', 'Portugal', 'Spain', 'Italy', 'Netherlands', 'Other');
-- Expected: 0


-- TEST S11: Gender values are standardized
SELECT
    'S11 - silver_products unexpected gender' AS test,
    COUNT(*) AS result
FROM silver_products
WHERE gender NOT IN ('Male', 'Female') AND gender IS NOT NULL;
-- Expected: 0


-- TEST S12: Color values are standardized
SELECT
    'S12 - silver_products unexpected color' AS test,
    COUNT(*) AS result
FROM silver_products
WHERE color NOT IN ('White', 'Black', 'Green', 'Red') AND color IS NOT NULL;
-- Expected: 0


-- TEST S13: No negative or null stock quantities
SELECT
    'S13 - silver_stock negative stock' AS test,
    COUNT(*) AS result
FROM silver_stock
WHERE stock_quantity < 0;
-- Expected: 0


-- TEST S14: Discount percent should be between 0 and 100
SELECT
    'S14 - silver_sales_items invalid discount_percent' AS test,
    COUNT(*) AS result
FROM silver_sales_items
WHERE discount_percent < 0 OR discount_percent > 100;
-- Expected: 0


-- TEST S15: sale_date in silver_sales_items should be in a valid range
-- (Adjust the date range based on your actual data)
SELECT
    'S15 - silver_sales_items out-of-range sale_date' AS test,
    COUNT(*) AS result
FROM silver_sales_items
WHERE sale_date < '2024-01-01' OR sale_date > CURDATE();
-- Expected: 0


-- ============================================================
-- GOLD LAYER TESTS
-- Goal: confirm star schema built correctly.
-- Check referential integrity, surrogate keys, and no orphan facts.
-- ============================================================

-- TEST G1: No duplicate surrogate keys in dim tables
SELECT
    'G1 - gold_dim_customer duplicate customer_key' AS test,
    COUNT(*) AS result
FROM (
    SELECT customer_key, COUNT(*) AS cnt
    FROM gold_dim_customer
    GROUP BY customer_key
    HAVING cnt > 1
) t
UNION ALL
SELECT
    'G1 - gold_dim_product duplicate product_key',
    COUNT(*)
FROM (
    SELECT product_key, COUNT(*) AS cnt
    FROM gold_dim_product
    GROUP BY product_key
    HAVING cnt > 1
) t
UNION ALL
SELECT
    'G1 - gold_dim_campaign duplicate campaign_key',
    COUNT(*)
FROM (
    SELECT campaign_key, COUNT(*) AS cnt
    FROM gold_dim_campaign
    GROUP BY campaign_key
    HAVING cnt > 1
) t;
-- Expected: all 0


-- TEST G2: No orphan fact rows — customer_key must exist in dim
SELECT
    'G2 - gold_fact_sales orphan customer_key' AS test,
    COUNT(*) AS result
FROM gold_fact_sales f
LEFT JOIN gold_dim_customer c ON f.customer_key = c.customer_key
WHERE c.customer_key IS NULL AND f.customer_key IS NOT NULL;
-- Expected: 0


-- TEST G3: No orphan fact rows — product_key must exist in dim
SELECT
    'G3 - gold_fact_sales orphan product_key' AS test,
    COUNT(*) AS result
FROM gold_fact_sales f
LEFT JOIN gold_dim_product p ON f.product_key = p.product_key
WHERE p.product_key IS NULL AND f.product_key IS NOT NULL;
-- Expected: 0


-- TEST G4: Null item_total in fact table
SELECT
    'G4 - gold_fact_sales null item_total' AS test,
    COUNT(*) AS result
FROM gold_fact_sales
WHERE item_total IS NULL;
-- Expected: 0


-- TEST G5: Negative item_total in fact table
SELECT
    'G5 - gold_fact_sales negative item_total' AS test,
    COUNT(*) AS result
FROM gold_fact_sales
WHERE item_total < 0;
-- Expected: 0


-- TEST G6: Null sale_date in fact table
SELECT
    'G6 - gold_fact_sales null sale_date' AS test,
    COUNT(*) AS result
FROM gold_fact_sales
WHERE sale_date IS NULL;
-- Expected: 0


-- TEST G7: Row counts consistent between silver and gold fact
-- silver_sales_items should match gold_fact_sales (1:1 on item_id)
SELECT
    'G7 - silver vs gold fact row count check' AS test,
    ABS(
        (SELECT COUNT(*) FROM silver_sales_items)
        - (SELECT COUNT(*) FROM gold_fact_sales)
    ) AS result;
-- Expected: 0 (counts match exactly)


-- TEST G8: No nulls on critical fact columns
SELECT
    'G8 - gold_fact_sales null sale_id'     AS test, COUNT(*) FROM gold_fact_sales WHERE sale_id IS NULL
UNION ALL
SELECT 'G8 - gold_fact_sales null channel',             COUNT(*) FROM gold_fact_sales WHERE channel IS NULL
UNION ALL
SELECT 'G8 - gold_fact_sales null quantity',            COUNT(*) FROM gold_fact_sales WHERE quantity IS NULL
UNION ALL
SELECT 'G8 - gold_fact_sales null unit_price',          COUNT(*) FROM gold_fact_sales WHERE unit_price IS NULL;
-- Expected: all 0


-- ============================================================
-- SUMMARY VIEW
-- A quick pass/fail output for all silver-layer tests combined.
-- Easier to scan when running tests after every pipeline run.
-- ============================================================

SELECT
    test_name,
    result,
    CASE WHEN result = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM (
    SELECT 'S1 - No duplicate customer_id'       AS test_name, COUNT(*) AS result FROM (SELECT customer_id, COUNT(*) c FROM silver_customers GROUP BY customer_id HAVING c > 1) t
    UNION ALL
    SELECT 'S2 - No duplicate sale_id',           COUNT(*) FROM (SELECT sale_id, COUNT(*) c FROM silver_sales GROUP BY sale_id HAVING c > 1) t
    UNION ALL
    SELECT 'S3 - No duplicate item_id',           COUNT(*) FROM (SELECT item_id, COUNT(*) c FROM silver_sales_items GROUP BY item_id HAVING c > 1) t
    UNION ALL
    SELECT 'S4 - No duplicate product_id',        COUNT(*) FROM (SELECT product_id, COUNT(*) c FROM silver_products GROUP BY product_id HAVING c > 1) t
    UNION ALL
    SELECT 'S5 - No invalid total_amount',        COUNT(*) FROM silver_sales WHERE total_amount <= 0
    UNION ALL
    SELECT 'S6 - No negative quantity',           COUNT(*) FROM silver_sales_items WHERE quantity < 0
    UNION ALL
    SELECT 'S10 - Country standardized',          COUNT(*) FROM silver_sales WHERE country NOT IN ('France','Germany','Portugal','Spain','Italy','Netherlands','Other')
    UNION ALL
    SELECT 'S11 - Gender standardized',           COUNT(*) FROM silver_products WHERE gender NOT IN ('Male','Female') AND gender IS NOT NULL
    UNION ALL
    SELECT 'G2 - No orphan customer_key',         COUNT(*) FROM gold_fact_sales f LEFT JOIN gold_dim_customer c ON f.customer_key = c.customer_key WHERE c.customer_key IS NULL AND f.customer_key IS NOT NULL
    UNION ALL
    SELECT 'G3 - No orphan product_key',          COUNT(*) FROM gold_fact_sales f LEFT JOIN gold_dim_product p ON f.product_key = p.product_key WHERE p.product_key IS NULL AND f.product_key IS NOT NULL
    UNION ALL
    SELECT 'G5 - No negative item_total',         COUNT(*) FROM gold_fact_sales WHERE item_total < 0
    UNION ALL
    SELECT 'G7 - Silver vs Gold row count match', ABS((SELECT COUNT(*) FROM silver_sales_items) - (SELECT COUNT(*) FROM gold_fact_sales))
) tests
ORDER BY status DESC, test_name;
