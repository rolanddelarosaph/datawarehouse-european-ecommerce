/*
===============================================================================
DDL Script : transform_silver.sql
Layer      : Silver (Cleaned & Standardized)
Database   : datawarehouse
===============================================================================
Purpose:
    Transforms raw Bronze data into cleaned, validated, and standardized
    Silver tables ready for analytical consumption.

Key Transformations:
    - Data type casting
    - Deduplication via ROW_NUMBER()
    - Null handling and string normalization
    - Business rule enforcement (country codes, color/gender abbreviations)
===============================================================================
*/

USE datawarehouse;

DROP PROCEDURE IF EXISTS transform_silver_layer;

DELIMITER $$

CREATE PROCEDURE transform_silver_layer()
BEGIN
	SET FOREIGN_KEY_CHECKS = 0;
    -- ============================================================
    -- CUSTOMERS
    -- ============================================================
    TRUNCATE TABLE silver_customers;

    INSERT INTO silver_customers (customer_id, country, age_range, signup_date)
    SELECT
        CAST(REPLACE(REPLACE(customer_id, 'CUST-', ''), '-X', '') AS SIGNED),
        TRIM(country),
        TRIM(age_range),
        CASE
            WHEN TRIM(signup_date) = '' THEN NULL
            ELSE CAST(signup_date AS DATE)
        END
    FROM (
        SELECT *,
               ROW_NUMBER() OVER (
                   PARTITION BY REPLACE(REPLACE(customer_id, 'CUST-', ''), '-X', '')
                   ORDER BY customer_id DESC
               ) AS rn
        FROM bronze_customers
        WHERE customer_id IS NOT NULL AND TRIM(customer_id) <> ''
    ) t
    WHERE rn = 1;


    -- ============================================================
    -- SALES
    -- ============================================================
    TRUNCATE TABLE silver_sales;

    INSERT INTO silver_sales (sale_id, channel, discounted, total_amount, sale_date, customer_id, country)
    SELECT
        CAST(SUBSTRING(sale_id, 4) AS SIGNED),
        TRIM(channel),
        CAST(discounted AS SIGNED),
        CASE
            WHEN ABS(total_amount) > 2000 THEN ABS(total_amount) / 10
            ELSE ABS(total_amount)
        END,
        CAST(sale_date AS DATE),
        CAST(customer_id AS SIGNED),
        CASE
            WHEN UPPER(TRIM(country)) IN ('FRANCE', 'FR')      THEN 'France'
            WHEN UPPER(TRIM(country)) IN ('GERMANY', 'DE')     THEN 'Germany'
            WHEN UPPER(TRIM(country)) IN ('PORTUGAL', 'PT')    THEN 'Portugal'
            WHEN UPPER(TRIM(country)) IN ('SPAIN', 'ES')       THEN 'Spain'
            WHEN UPPER(TRIM(country)) IN ('ITALY', 'IT')       THEN 'Italy'
            WHEN UPPER(TRIM(country)) IN ('NETHERLANDS', 'NL') THEN 'Netherlands'
            ELSE 'Other'
        END
    FROM bronze_sales;


    -- ============================================================
    -- SALES ITEMS
    -- ============================================================
    TRUNCATE TABLE silver_sales_items;

    INSERT INTO silver_sales_items
    (item_id, sale_id, product_id, quantity, original_price, unit_price,
     discount_applied, discount_percent, discounted, item_total,
     sale_date, channel, channel_campaigns)
    SELECT
        CAST(item_id AS UNSIGNED),
        CAST(sale_id AS UNSIGNED),
        CAST(product_id AS UNSIGNED),
        ABS(quantity),
        CAST(original_price AS DECIMAL(10,2)),
        CAST(unit_price AS DECIMAL(10,2)),
        CAST(discount_applied AS DECIMAL(10,2)),
        CAST(REPLACE(discount_percent, '%', '') AS DECIMAL(10,2)),
        CAST(discounted AS UNSIGNED),
        CAST(item_total AS DECIMAL(10,2)),
        CASE
		    WHEN sale_date LIKE '%/%' THEN STR_TO_DATE(sale_date, '%m/%d/%y')
		    ELSE CAST(sale_date AS DATE)
		END,
        TRIM(channel),
        TRIM(channel_campaigns)
    FROM (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY item_id ORDER BY sale_date DESC) AS rn
        FROM bronze_sales_items
    ) t
    WHERE rn = 1;


    -- ============================================================
    -- PRODUCTS
    -- ============================================================
    TRUNCATE TABLE silver_products;

    INSERT INTO silver_products
    (product_id, product_name, category, brand, color, size, catalog_price, cost_price, gender)
    SELECT DISTINCT
        CAST(product_id AS SIGNED),
        TRIM(product_name),
        TRIM(category),
        TRIM(brand),
        CASE
            WHEN UPPER(TRIM(color)) IN ('WHITE', 'W') THEN 'White'
            WHEN UPPER(TRIM(color)) IN ('BLACK', 'B') THEN 'Black'
            WHEN UPPER(TRIM(color)) IN ('GREEN', 'G') THEN 'Green'
            WHEN UPPER(TRIM(color)) IN ('RED', 'R')   THEN 'Red'
        END,
        size,
        CAST(catalog_price AS DECIMAL(10,2)),
        CAST(cost_price AS DECIMAL(10,2)),
        CASE
            WHEN UPPER(TRIM(gender)) IN ('FEMALE', 'F') THEN 'Female'
            WHEN UPPER(TRIM(gender)) IN ('MALE', 'M')   THEN 'Male'
        END
    FROM bronze_products;


    -- ============================================================
    -- STOCK
    -- ============================================================
    TRUNCATE TABLE silver_stock;

    INSERT INTO silver_stock (country, product_id, stock_quantity)
    SELECT
        CASE
            WHEN UPPER(TRIM(country)) IN ('FR', 'FRANCE')     THEN 'France'
            WHEN UPPER(TRIM(country)) IN ('DE', 'GERMANY')    THEN 'Germany'
            WHEN UPPER(TRIM(country)) IN ('PT', 'PORTUGAL')   THEN 'Portugal'
            WHEN UPPER(TRIM(country)) IN ('ES', 'SPAIN')      THEN 'Spain'
            WHEN UPPER(TRIM(country)) IN ('IT', 'ITALY')      THEN 'Italy'
            WHEN UPPER(TRIM(country)) IN ('NL', 'NETHERLANDS') THEN 'Netherlands'
            ELSE 'Other'
        END,
        CAST(SUBSTRING(product_id, 4) AS SIGNED),
        CAST(stock_quantity AS SIGNED)
    FROM bronze_stock;


    -- ============================================================
	-- CAMPAIGNS
	-- ============================================================
	TRUNCATE TABLE silver_campaigns;
	
	INSERT INTO silver_campaigns
	(campaign_id, campaign_name, start_date, end_date, channel, discount_type, discount_value)
	SELECT
	    CAST(campaign_id AS UNSIGNED),
	    TRIM(campaign_name),
	    CAST(start_date AS DATE),
	    CAST(end_date AS DATE),
	    TRIM(channel),
	    TRIM(discount_type),
	    CAST(REPLACE(discount_value, '%', '') AS DECIMAL(10,2))
	FROM (
	    SELECT *,
	           ROW_NUMBER() OVER (PARTITION BY campaign_id ORDER BY campaign_id) AS rn
	    FROM bronze_campaigns
	) t
	WHERE rn = 1;


    -- ============================================================
	-- CHANNELS
	-- ============================================================
	TRUNCATE TABLE silver_channels;
	
	INSERT INTO silver_channels (channel, description)
	SELECT
	    TRIM(channel),
	    CASE
	        WHEN LOWER(TRIM(description)) = 'brand mobile app'      THEN 'Brand Mobile App'
	        WHEN LOWER(TRIM(description)) = 'official online store' THEN 'Official Online Store'
	        ELSE TRIM(description)
	    END
	FROM (
	    SELECT *,
	           ROW_NUMBER() OVER (PARTITION BY channel ORDER BY channel) AS rn
	    FROM bronze_channels
	) t
	WHERE rn = 1;
    
    SET FOREIGN_KEY_CHECKS = 1;
END $$

DELIMITER ;