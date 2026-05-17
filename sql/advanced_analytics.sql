-- ============================================================
-- SCRIPT : advanced_analytics.sql
-- PURPOSE: Business Analytics — Fashion Store Data Warehouse
-- Layer  : Gold (star schema)
-- Notes  : Answers key business questions across sales,
--          products, customers, campaigns, and inventory.
-- ============================================================

USE datawarehouse;


-- ============================================================
-- Q1: What is the total revenue, total orders, and average
--     order value per month?
-- (Revenue trend over time)
-- ============================================================

SELECT
    DATE_FORMAT(f.sale_date, '%Y-%m')  AS sale_month,
    COUNT(DISTINCT f.sale_id)          AS total_orders,
    ROUND(SUM(f.item_total), 2)        AS total_revenue,
    ROUND(AVG(f.total_amount), 2)      AS avg_order_value
FROM gold_fact_sales f
GROUP BY sale_month
ORDER BY sale_month;


-- ============================================================
-- Q2: Which product category generates the most revenue?
--     And how does it rank across all categories?
-- ============================================================

SELECT
    p.category,
    COUNT(*)                    AS items_sold,
    SUM(f.quantity)             AS total_units,
    ROUND(SUM(f.item_total), 2) AS total_revenue,
    RANK() OVER (ORDER BY SUM(f.item_total) DESC) AS revenue_rank
FROM gold_fact_sales f
JOIN gold_dim_product p ON f.product_key = p.product_key
GROUP BY p.category
ORDER BY revenue_rank;


-- ============================================================
-- Q3: Which are the top 10 best-selling products by revenue?
-- ============================================================

SELECT
    p.product_name,
    p.category,
    p.brand,
    SUM(f.quantity)             AS units_sold,
    ROUND(SUM(f.item_total), 2) AS total_revenue
FROM gold_fact_sales f
JOIN gold_dim_product p ON f.product_key = p.product_key
GROUP BY p.product_id, p.product_name, p.category, p.brand
ORDER BY total_revenue DESC
LIMIT 10;


-- ============================================================
-- Q4: How does each sales channel perform?
--     (Revenue, order count, avg order value)
-- ============================================================

SELECT
    f.channel,
    COUNT(DISTINCT f.sale_id)          AS total_orders,
    ROUND(SUM(f.item_total), 2)        AS total_revenue,
    ROUND(AVG(f.total_amount), 2)      AS avg_order_value,
    ROUND(SUM(f.item_total) / SUM(SUM(f.item_total)) OVER () * 100, 1) AS revenue_share_pct
FROM gold_fact_sales f
GROUP BY f.channel
ORDER BY total_revenue DESC;


-- ============================================================
-- Q5: Which country has the most revenue and the most orders?
--     How does it break down?
-- ============================================================

SELECT
    c.country,
    COUNT(DISTINCT f.sale_id)   AS total_orders,
    SUM(f.quantity)             AS total_units_sold,
    ROUND(SUM(f.item_total), 2) AS total_revenue,
    ROUND(AVG(f.total_amount), 2) AS avg_order_value
FROM gold_fact_sales f
JOIN gold_dim_customer c ON f.customer_key = c.customer_key
GROUP BY c.country
ORDER BY total_revenue DESC;


-- ============================================================
-- Q6: What is the discount impact?
--     Discounted vs non-discounted orders —
--     revenue, order count, average discount.
-- ============================================================

SELECT
    CASE WHEN f.discount_applied > 0 THEN 'Discounted' ELSE 'Full Price' END AS order_type,
    COUNT(DISTINCT f.sale_id)          AS total_orders,
    ROUND(SUM(f.item_total), 2)        AS total_revenue,
    ROUND(AVG(f.discount_applied), 2)  AS avg_discount_amount,
    ROUND(AVG(f.total_amount), 2)      AS avg_order_value
FROM gold_fact_sales f
GROUP BY order_type
ORDER BY total_revenue DESC;


-- ============================================================
-- Q7: Which campaigns generated the most revenue?
--     And what was the average discount they offered?
-- ============================================================

SELECT
    cp.campaign_name,
    cp.channel,
    cp.discount_type,
    cp.discount_value,
    COUNT(DISTINCT f.sale_id)   AS total_orders,
    ROUND(SUM(f.item_total), 2) AS total_revenue,
    ROUND(AVG(f.discount_applied), 2) AS avg_discount_applied
FROM gold_fact_sales f
JOIN gold_dim_campaign cp ON f.campaign_key = cp.campaign_key
GROUP BY cp.campaign_id, cp.campaign_name, cp.channel, cp.discount_type, cp.discount_value
ORDER BY total_revenue DESC;


-- ============================================================
-- Q8: Customer segmentation by age group.
--     Which age range spends the most?
-- ============================================================

SELECT
    c.age_range,
    COUNT(DISTINCT f.sale_id)    AS total_orders,
    COUNT(DISTINCT c.customer_id) AS unique_customers,
    ROUND(SUM(f.item_total), 2)  AS total_revenue,
    ROUND(AVG(f.total_amount), 2) AS avg_order_value
FROM gold_fact_sales f
JOIN gold_dim_customer c ON f.customer_key = c.customer_key
GROUP BY c.age_range
ORDER BY total_revenue DESC;


-- ============================================================
-- Q9: Who are the top 10 customers by lifetime value?
-- ============================================================

SELECT
    c.customer_id,
    c.country,
    c.age_range,
    COUNT(DISTINCT f.sale_id)    AS total_orders,
    ROUND(SUM(f.item_total), 2)  AS lifetime_value,
    ROUND(AVG(f.total_amount), 2) AS avg_order_value
FROM gold_fact_sales f
JOIN gold_dim_customer c ON f.customer_key = c.customer_key
GROUP BY c.customer_id, c.country, c.age_range
ORDER BY lifetime_value DESC
LIMIT 10;


-- ============================================================
-- Q10: Revenue by brand — which brands drive the most sales?
-- ============================================================

SELECT
    p.brand,
    COUNT(*)                    AS items_sold,
    SUM(f.quantity)             AS total_units,
    ROUND(SUM(f.item_total), 2) AS total_revenue,
    ROUND(AVG(p.catalog_price), 2) AS avg_catalog_price
FROM gold_fact_sales f
JOIN gold_dim_product p ON f.product_key = p.product_key
GROUP BY p.brand
ORDER BY total_revenue DESC;


-- ============================================================
-- Q11: Gender-based sales — Male vs Female products.
--     Which gender segment drives more revenue?
-- ============================================================

SELECT
    p.gender,
    COUNT(DISTINCT f.sale_id)   AS total_orders,
    SUM(f.quantity)             AS total_units,
    ROUND(SUM(f.item_total), 2) AS total_revenue
FROM gold_fact_sales f
JOIN gold_dim_product p ON f.product_key = p.product_key
WHERE p.gender IS NOT NULL
GROUP BY p.gender
ORDER BY total_revenue DESC;


-- ============================================================
-- Q12: Week-over-week revenue — is the business growing?
-- ============================================================

WITH weekly AS (
    SELECT
        YEARWEEK(sale_date, 1)              AS yr_week,
        MIN(sale_date)                      AS week_start,
        ROUND(SUM(item_total), 2)           AS weekly_revenue
    FROM gold_fact_sales
    GROUP BY yr_week
)
SELECT
    week_start,
    weekly_revenue,
    LAG(weekly_revenue) OVER (ORDER BY yr_week)  AS prev_week_revenue,
    ROUND(
        (weekly_revenue - LAG(weekly_revenue) OVER (ORDER BY yr_week))
        / LAG(weekly_revenue) OVER (ORDER BY yr_week) * 100,
    1) AS wow_growth_pct
FROM weekly
ORDER BY week_start;


-- ============================================================
-- Q13: Category revenue breakdown per country.
--     Which categories are dominant in each market?
-- ============================================================

SELECT
    c.country,
    p.category,
    ROUND(SUM(f.item_total), 2) AS total_revenue,
    RANK() OVER (
        PARTITION BY c.country
        ORDER BY SUM(f.item_total) DESC
    ) AS rank_in_country
FROM gold_fact_sales f
JOIN gold_dim_customer c ON f.customer_key = c.customer_key
JOIN gold_dim_product  p ON f.product_key  = p.product_key
GROUP BY c.country, p.category
ORDER BY c.country, rank_in_country;


-- ============================================================
-- Q14: Stockout risk — products with low stock vs how much
--      they actually sold. Priority restocking view.
-- ============================================================

SELECT
    p.product_id,
    p.product_name,
    p.category,
    st.country,
    st.stock_quantity,
    COALESCE(SUM(f.quantity), 0)  AS total_units_sold,
    CASE
        WHEN st.stock_quantity = 0                    THEN 'Out of Stock'
        WHEN st.stock_quantity < 10                   THEN 'Critical'
        WHEN st.stock_quantity < 30                   THEN 'Low'
        ELSE 'Okay'
    END AS stock_status
FROM silver_stock st
JOIN silver_products p  ON st.product_id = p.product_id
LEFT JOIN gold_dim_product gp ON p.product_id = gp.product_id
LEFT JOIN gold_fact_sales  f  ON gp.product_key = f.product_key
GROUP BY p.product_id, p.product_name, p.category, st.country, st.stock_quantity
ORDER BY stock_quantity ASC, total_units_sold DESC;
