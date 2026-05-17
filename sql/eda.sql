-- ============================================================
-- SCRIPT : eda.sql
-- PURPOSE: Exploratory Data Analysis — Fashion Store
-- Layer  : Silver (post-cleaning)
-- Notes  : Run after the pipeline has completed successfully.
--          These are investigative queries, not reports.
-- ============================================================

USE datawarehouse;


-- ============================================================
-- SECTION 1: ROW COUNTS
-- Just checking that every table loaded with the expected rows.
-- ============================================================

SELECT 'silver_customers'  AS table_name, COUNT(*) AS row_count FROM silver_customers
UNION ALL
SELECT 'silver_sales',                     COUNT(*) FROM silver_sales
UNION ALL
SELECT 'silver_sales_items',               COUNT(*) FROM silver_sales_items
UNION ALL
SELECT 'silver_products',                  COUNT(*) FROM silver_products
UNION ALL
SELECT 'silver_stock',                     COUNT(*) FROM silver_stock
UNION ALL
SELECT 'silver_channels',                  COUNT(*) FROM silver_channels
UNION ALL
SELECT 'silver_campaigns',                 COUNT(*) FROM silver_campaigns;


-- ============================================================
-- SECTION 2: CUSTOMERS
-- ============================================================

-- Age distribution
SELECT
    age_range,
    COUNT(*) AS customer_count
FROM silver_customers
GROUP BY age_range
ORDER BY customer_count DESC;

-- Customers by country
SELECT
    country,
    COUNT(*) AS customer_count
FROM silver_customers
GROUP BY country
ORDER BY customer_count DESC;

-- Signup trend by month — when did most customers join?
SELECT
    DATE_FORMAT(signup_date, '%Y-%m') AS signup_month,
    COUNT(*) AS new_customers
FROM silver_customers
WHERE signup_date IS NOT NULL
GROUP BY signup_month
ORDER BY signup_month;

-- Any nulls in key fields?
SELECT
    SUM(CASE WHEN customer_id  IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN country      IS NULL THEN 1 ELSE 0 END) AS null_country,
    SUM(CASE WHEN age_range    IS NULL THEN 1 ELSE 0 END) AS null_age_range,
    SUM(CASE WHEN signup_date  IS NULL THEN 1 ELSE 0 END) AS null_signup_date
FROM silver_customers;


-- ============================================================
-- SECTION 3: PRODUCTS
-- ============================================================

-- How many products per category?
SELECT
    category,
    COUNT(*) AS product_count
FROM silver_products
GROUP BY category
ORDER BY product_count DESC;

-- Products per brand
SELECT
    brand,
    COUNT(*) AS product_count
FROM silver_products
GROUP BY brand
ORDER BY product_count DESC;

-- Gender split
SELECT
    gender,
    COUNT(*) AS product_count
FROM silver_products
GROUP BY gender;

-- Price range — just a quick feel for the data
SELECT
    MIN(catalog_price) AS min_price,
    MAX(catalog_price) AS max_price,
    ROUND(AVG(catalog_price), 2) AS avg_price,
    ROUND(AVG(cost_price), 2)    AS avg_cost
FROM silver_products;

-- Margin per category
SELECT
    category,
    ROUND(AVG(catalog_price - cost_price), 2) AS avg_margin,
    ROUND(AVG((catalog_price - cost_price) / catalog_price) * 100, 1) AS avg_margin_pct
FROM silver_products
GROUP BY category
ORDER BY avg_margin DESC;

-- Null check
SELECT
    SUM(CASE WHEN product_name   IS NULL THEN 1 ELSE 0 END) AS null_name,
    SUM(CASE WHEN category       IS NULL THEN 1 ELSE 0 END) AS null_category,
    SUM(CASE WHEN catalog_price  IS NULL THEN 1 ELSE 0 END) AS null_catalog_price,
    SUM(CASE WHEN cost_price     IS NULL THEN 1 ELSE 0 END) AS null_cost_price,
    SUM(CASE WHEN gender         IS NULL THEN 1 ELSE 0 END) AS null_gender,
    SUM(CASE WHEN color          IS NULL THEN 1 ELSE 0 END) AS null_color
FROM silver_products;


-- ============================================================
-- SECTION 4: SALES
-- ============================================================

-- Overall sales numbers
SELECT
    COUNT(*)                       AS total_sales,
    ROUND(SUM(total_amount), 2)    AS total_revenue,
    ROUND(AVG(total_amount), 2)    AS avg_order_value,
    MIN(total_amount)              AS min_order,
    MAX(total_amount)              AS max_order
FROM silver_sales;

-- Sales by channel
SELECT
    channel,
    COUNT(*)                    AS sale_count,
    ROUND(SUM(total_amount), 2) AS total_revenue
FROM silver_sales
GROUP BY channel
ORDER BY total_revenue DESC;

-- Sales by country
SELECT
    country,
    COUNT(*)                    AS sale_count,
    ROUND(SUM(total_amount), 2) AS total_revenue
FROM silver_sales
GROUP BY country
ORDER BY total_revenue DESC;

-- How many sales had a discount applied?
SELECT
    discounted,
    COUNT(*) AS sale_count,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER () * 100, 1) AS pct
FROM silver_sales
GROUP BY discounted;

-- Sale volume per month
SELECT
    DATE_FORMAT(sale_date, '%Y-%m') AS sale_month,
    COUNT(*)                        AS sale_count,
    ROUND(SUM(total_amount), 2)     AS monthly_revenue
FROM silver_sales
GROUP BY sale_month
ORDER BY sale_month;

-- Date range of sales data
SELECT
    MIN(sale_date) AS earliest_sale,
    MAX(sale_date) AS latest_sale
FROM silver_sales;

-- Null check
SELECT
    SUM(CASE WHEN sale_id      IS NULL THEN 1 ELSE 0 END) AS null_sale_id,
    SUM(CASE WHEN channel      IS NULL THEN 1 ELSE 0 END) AS null_channel,
    SUM(CASE WHEN total_amount IS NULL THEN 1 ELSE 0 END) AS null_total_amount,
    SUM(CASE WHEN customer_id  IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN sale_date    IS NULL THEN 1 ELSE 0 END) AS null_sale_date
FROM silver_sales;


-- ============================================================
-- SECTION 5: SALES ITEMS
-- ============================================================

-- General item stats
SELECT
    COUNT(*)                          AS total_items,
    ROUND(AVG(quantity), 2)           AS avg_qty,
    ROUND(AVG(unit_price), 2)         AS avg_unit_price,
    ROUND(AVG(discount_applied), 2)   AS avg_discount,
    ROUND(AVG(item_total), 2)         AS avg_item_total
FROM silver_sales_items;

-- Items by channel
SELECT
    channel,
    COUNT(*)                    AS item_count,
    ROUND(SUM(item_total), 2)   AS total_revenue
FROM silver_sales_items
GROUP BY channel
ORDER BY total_revenue DESC;

-- Campaign breakdown — which campaigns drove the most items?
SELECT
    channel_campaigns,
    COUNT(*)                    AS item_count,
    ROUND(SUM(item_total), 2)   AS total_revenue
FROM silver_sales_items
GROUP BY channel_campaigns
ORDER BY total_revenue DESC;

-- How often are discounts actually applied at item level?
SELECT
    discounted,
    COUNT(*) AS item_count,
    ROUND(AVG(discount_percent), 2) AS avg_discount_pct
FROM silver_sales_items
GROUP BY discounted;

-- Null check on important columns
SELECT
    SUM(CASE WHEN item_id         IS NULL THEN 1 ELSE 0 END) AS null_item_id,
    SUM(CASE WHEN sale_id         IS NULL THEN 1 ELSE 0 END) AS null_sale_id,
    SUM(CASE WHEN product_id      IS NULL THEN 1 ELSE 0 END) AS null_product_id,
    SUM(CASE WHEN quantity        IS NULL THEN 1 ELSE 0 END) AS null_quantity,
    SUM(CASE WHEN item_total      IS NULL THEN 1 ELSE 0 END) AS null_item_total,
    SUM(CASE WHEN channel_campaigns IS NULL THEN 1 ELSE 0 END) AS null_campaigns
FROM silver_sales_items;


-- ============================================================
-- SECTION 6: STOCK
-- ============================================================

-- Stock summary per country
SELECT
    country,
    COUNT(DISTINCT product_id)      AS unique_products,
    SUM(stock_quantity)             AS total_stock,
    ROUND(AVG(stock_quantity), 1)   AS avg_stock_per_product
FROM silver_stock
GROUP BY country
ORDER BY total_stock DESC;

-- Products with very low stock (potential stockout risk)
SELECT
    country,
    product_id,
    stock_quantity
FROM silver_stock
WHERE stock_quantity < 10
ORDER BY stock_quantity ASC;

-- Overall stock range
SELECT
    MIN(stock_quantity) AS min_stock,
    MAX(stock_quantity) AS max_stock,
    ROUND(AVG(stock_quantity), 1) AS avg_stock
FROM silver_stock;


-- ============================================================
-- SECTION 7: CAMPAIGNS
-- ============================================================

SELECT
    campaign_id,
    campaign_name,
    channel,
    discount_type,
    discount_value,
    start_date,
    end_date,
    DATEDIFF(end_date, start_date) AS duration_days
FROM silver_campaigns
ORDER BY start_date;


-- ============================================================
-- SECTION 8: QUICK JOINS — SANITY CHECKS
-- ============================================================

-- How many sales don't have a matching customer?
SELECT COUNT(*) AS unmatched_sales
FROM silver_sales s
LEFT JOIN silver_customers c ON s.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- How many sales items don't have a matching product?
SELECT COUNT(*) AS unmatched_items
FROM silver_sales_items i
LEFT JOIN silver_products p ON i.product_id = p.product_id
WHERE p.product_id IS NULL;

-- How many sales items don't link back to a sale?
SELECT COUNT(*) AS orphan_items
FROM silver_sales_items i
LEFT JOIN silver_sales s ON i.sale_id = s.sale_id
WHERE s.sale_id IS NULL;
