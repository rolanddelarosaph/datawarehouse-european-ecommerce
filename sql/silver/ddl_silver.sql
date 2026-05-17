-- ============================================
-- SCRIPT: ddl_silver.sql
-- PURPOSE:
-- This script creates Silver tables with cleaned,
-- standardized, and properly typed data.
-- It retains source-level detail while enforcing
-- structure and data integrity.
-- ============================================

USE datawarehouse;

-- CUSTOMERS
DROP TABLE IF EXISTS silver_customers;

CREATE TABLE silver_customers(
    customer_id INT PRIMARY KEY,
    country VARCHAR(50),
    age_range VARCHAR(50),
    signup_date DATE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);


-- SALES
DROP TABLE IF EXISTS silver_sales;

CREATE TABLE silver_sales (
    sale_id INT PRIMARY KEY,
    channel VARCHAR(50),
    discounted BOOLEAN,
    total_amount DECIMAL(10,2),
    sale_date DATE,
    customer_id INT,
    country VARCHAR(50),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);


-- SALES ITEMS (FIXED TYPES)
DROP TABLE IF EXISTS silver_sales_items;

CREATE TABLE silver_sales_items (
    item_id INT PRIMARY KEY,
    sale_id INT,
    product_id INT,
    quantity INT,
    original_price DECIMAL(10,2),
    unit_price DECIMAL(10,2),
    discount_applied DECIMAL(10,2),
    discount_percent DECIMAL(5,2),
    discounted BOOLEAN,
    item_total DECIMAL(10,2),
    sale_date DATE,
    channel VARCHAR(100),
    channel_campaigns VARCHAR(100),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);


-- PRODUCTS
DROP TABLE IF EXISTS silver_products;

CREATE TABLE silver_products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(150),
    category VARCHAR(100),
    brand VARCHAR(50),
    color VARCHAR(50),
    size VARCHAR(50),
    catalog_price DECIMAL(10,2),
    cost_price DECIMAL(10,2),
    gender VARCHAR(50),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);


-- STOCK
DROP TABLE IF EXISTS silver_stock;

CREATE TABLE silver_stock (
    country VARCHAR(50),
    product_id INT,
    stock_quantity INT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);


-- CHANNELS
DROP TABLE IF EXISTS silver_channels;

CREATE TABLE silver_channels (
    channel VARCHAR(50) PRIMARY KEY,
    description VARCHAR(50),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);


-- CAMPAIGNS
DROP TABLE IF EXISTS silver_campaigns;

CREATE TABLE silver_campaigns (
    campaign_id INT PRIMARY KEY,
    campaign_name VARCHAR(100),
    start_date DATE,
    end_date DATE,
    channel VARCHAR(50),
    discount_type VARCHAR(50),
    discount_value DECIMAL(10,2),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);