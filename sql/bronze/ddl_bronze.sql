/*
===============================================================================
DDL Script : ddl_bronze.sql
Layer      : Bronze (Raw Ingestion)
Database   : datawarehouse
===============================================================================
Purpose:
    Creates raw ingestion tables for the Bronze layer of a Medallion
    Architecture pipeline (Bronze → Silver → Gold).

Design Principles:
    - All columns stored as VARCHAR to preserve raw source data exactly as-is
    - Zero transformations at this layer — data fidelity is the priority
    - Tables are dropped and recreated on each pipeline run for idempotency
    - Ordering respects logical data domain groupings (customers, products,
      sales, inventory, marketing)

Pipeline Flow:
    CSV Files → Bronze (raw) → Silver (cleaned) → Gold (star schema)
===============================================================================
*/

USE datawarehouse;

-- ============================================================
-- DROP TABLES (reverse dependency order for safety)
-- ============================================================
DROP TABLE IF EXISTS bronze_sales_items;
DROP TABLE IF EXISTS bronze_sales;
DROP TABLE IF EXISTS bronze_campaigns;
DROP TABLE IF EXISTS bronze_channels;
DROP TABLE IF EXISTS bronze_stock;
DROP TABLE IF EXISTS bronze_products;
DROP TABLE IF EXISTS bronze_customers;


-- ============================================================
-- DOMAIN: CUSTOMERS
-- Source : data/raw/commerce/customers.csv
-- ============================================================
CREATE TABLE bronze_customers (
    customer_id     VARCHAR(50),    -- Raw ID e.g. 'CUST-001', 'CUST-001-X'
    country         VARCHAR(50),
    age_range       VARCHAR(50),    -- e.g. '18-24', '25-34'
    signup_date     VARCHAR(50)     -- Raw date string; cast in Silver layer
);


-- ============================================================
-- DOMAIN: PRODUCTS
-- Source : data/raw/commerce/products.csv
-- ============================================================
CREATE TABLE bronze_products (
    product_id      VARCHAR(50),
    product_name    VARCHAR(150),
    category        VARCHAR(100),
    brand           VARCHAR(50),
    color           VARCHAR(50),    -- May contain abbreviations e.g. 'W', 'B'
    size            VARCHAR(50),
    catalog_price   VARCHAR(50),    -- Raw decimal string; cast in Silver layer
    cost_price      VARCHAR(50),    -- Raw decimal string; cast in Silver layer
    gender          VARCHAR(50)     -- May contain abbreviations e.g. 'M', 'F'
);


-- ============================================================
-- DOMAIN: SALES
-- Source : data/raw/commerce/sales.csv
-- ============================================================
CREATE TABLE bronze_sales (
    sale_id         VARCHAR(50),    -- Raw ID e.g. 'SAL-001'
    channel         VARCHAR(50),
    discounted      VARCHAR(50),    -- Raw boolean string e.g. '0', '1'
    total_amount    VARCHAR(50),    -- May contain sign issues; corrected in Silver
    sale_date       VARCHAR(50),
    customer_id     VARCHAR(50),
    country         VARCHAR(50)     -- May contain abbreviations e.g. 'FR', 'DE'
);


-- ============================================================
-- DOMAIN: SALES ITEMS
-- Source : data/raw/commerce/sales_items.csv
-- ============================================================
CREATE TABLE bronze_sales_items (
    item_id             VARCHAR(50),
    sale_id             VARCHAR(50),
    product_id          VARCHAR(50),
    quantity            VARCHAR(50),    -- May contain negative values
    original_price      VARCHAR(50),
    unit_price          VARCHAR(50),
    discount_applied    VARCHAR(50),
    discount_percent    VARCHAR(50),    -- May contain '%' suffix e.g. '10%'
    discounted          VARCHAR(50),
    item_total          VARCHAR(50),
    sale_date           VARCHAR(50),
    channel             VARCHAR(100),
    channel_campaigns   VARCHAR(100)
);


-- ============================================================
-- DOMAIN: STOCK / INVENTORY
-- Source : data/raw/operations/stock.csv
-- ============================================================
CREATE TABLE bronze_stock (
    country         VARCHAR(50),    -- May contain abbreviations e.g. 'FR', 'DE'
    product_id      VARCHAR(50),    -- Raw ID e.g. 'PRD-001'
    stock_quantity  VARCHAR(50)
);


-- ============================================================
-- DOMAIN: CHANNELS
-- Source : data/raw/operations/channels.csv
-- ============================================================
CREATE TABLE bronze_channels (
    channel         VARCHAR(50),
    description     VARCHAR(100)    -- Increased from 50; descriptions may be longer
);


-- ============================================================
-- DOMAIN: CAMPAIGNS / MARKETING
-- Source : data/raw/operations/campaigns.csv
-- ============================================================
CREATE TABLE bronze_campaigns (
    campaign_id     VARCHAR(50),
    campaign_name   VARCHAR(100),
    start_date      VARCHAR(50),
    end_date        VARCHAR(50),
    channel         VARCHAR(50),
    discount_type   VARCHAR(50),
    discount_value  VARCHAR(50)     -- May contain '%' suffix; stripped in Silver
);