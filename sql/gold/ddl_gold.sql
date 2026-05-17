/*
===============================================================================
SCRIPT: ddl_gold.sql
PURPOSE:
Creates Gold layer star schema (dimension + fact tables).
This layer is materialized for performance and analytics.

DESIGN:
- Surrogate keys (AUTO_INCREMENT)
- Referential integrity
- Indexed fact table
===============================================================================
*/

USE datawarehouse;

-- =========================
-- DIM: CUSTOMER
-- =========================
DROP TABLE IF EXISTS gold_dim_customer;

CREATE TABLE gold_dim_customer (
    customer_key INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    country VARCHAR(50),
    age_range VARCHAR(50),
    signup_date DATE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (customer_id)
);

INSERT INTO gold_dim_customer (customer_id, country, age_range, signup_date)
SELECT DISTINCT
    customer_id,
    country,
    age_range,
    signup_date
FROM silver_customers;


-- =========================
-- DIM: PRODUCT
-- =========================
DROP TABLE IF EXISTS gold_dim_product;

CREATE TABLE gold_dim_product (
    product_key INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    product_name VARCHAR(150),
    category VARCHAR(100),
    brand VARCHAR(50),
    color VARCHAR(50),
    size VARCHAR(50),
    gender VARCHAR(50),
    catalog_price DECIMAL(10,2),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (product_id)
);

INSERT INTO gold_dim_product (
    product_id, product_name, category, brand,
    color, size, gender, catalog_price
)
SELECT DISTINCT
    product_id,
    product_name,
    category,
    brand,
    color,
    size,
    gender,
    catalog_price
FROM silver_products;


-- =========================
-- DIM: CAMPAIGN
-- =========================
DROP TABLE IF EXISTS gold_dim_campaign;

CREATE TABLE gold_dim_campaign (
    campaign_key INT AUTO_INCREMENT PRIMARY KEY,
    campaign_id INT NOT NULL,
    campaign_name VARCHAR(100),
    discount_type VARCHAR(50),
    discount_value DECIMAL(10,2),
    start_date DATE,
    end_date DATE,
    channel VARCHAR(50),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (campaign_id)
);

INSERT INTO gold_dim_campaign (
    campaign_id, campaign_name, discount_type,
    discount_value, start_date, end_date, channel
)
SELECT DISTINCT
    campaign_id,
    campaign_name,
    discount_type,
    discount_value,
    start_date,
    end_date,
    channel
FROM silver_campaigns;


-- =========================
-- FACT: SALES
-- =========================
DROP TABLE IF EXISTS gold_fact_sales;

CREATE TABLE gold_fact_sales (
    item_id INT PRIMARY KEY,
    sale_id INT,

    customer_key INT,
    product_key INT,
    campaign_key INT,

    channel VARCHAR(50),
    sale_date DATE,

    quantity INT,
    unit_price DECIMAL(10,2),
    discount_applied DECIMAL(10,2),
    item_total DECIMAL(10,2),
    total_amount DECIMAL(10,2),

    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (customer_key) REFERENCES gold_dim_customer(customer_key),
    FOREIGN KEY (product_key) REFERENCES gold_dim_product(product_key),
    FOREIGN KEY (campaign_key) REFERENCES gold_dim_campaign(campaign_key)
);

INSERT INTO gold_fact_sales (
    item_id, sale_id,
    customer_key, product_key, campaign_key,
    channel, sale_date,
    quantity, unit_price, discount_applied, item_total, total_amount
)
SELECT
    i.item_id,
    i.sale_id,
    c.customer_key,
    p.product_key,
    cp.campaign_key,
    i.channel,
    i.sale_date,
    i.quantity,
    i.unit_price,
    i.discount_applied,
    i.item_total,
    s.total_amount
FROM silver_sales_items i
JOIN silver_sales s
    ON i.sale_id = s.sale_id
LEFT JOIN gold_dim_customer c
    ON s.customer_id = c.customer_id
LEFT JOIN gold_dim_product p
    ON i.product_id = p.product_id
LEFT JOIN gold_dim_campaign cp
    ON i.channel = cp.channel
   AND i.sale_date BETWEEN cp.start_date AND cp.end_date;


-- =========================
-- INDEXES
-- =========================
CREATE INDEX idx_fact_customer ON gold_fact_sales(customer_key);
CREATE INDEX idx_fact_product ON gold_fact_sales(product_key);
CREATE INDEX idx_fact_campaign ON gold_fact_sales(campaign_key);
CREATE INDEX idx_fact_date ON gold_fact_sales(sale_date);


/*
===============================================================================
SCRIPT: views_gold.sql
PURPOSE:
Creates BI-friendly views on top of Gold tables.
These views simplify queries for dashboards and reporting.
===============================================================================
*/

USE datawarehouse;

-- =========================
-- CUSTOMER VIEW
-- =========================
CREATE OR REPLACE VIEW vw_dim_customer AS
SELECT * FROM gold_dim_customer;


-- =========================
-- PRODUCT VIEW
-- =========================
CREATE OR REPLACE VIEW vw_dim_product AS
SELECT * FROM gold_dim_product;


-- =========================
-- CAMPAIGN VIEW
-- =========================
CREATE OR REPLACE VIEW vw_dim_campaign AS
SELECT * FROM gold_dim_campaign;

-- =========================
-- FACT VIEW (JOINED)
-- =========================
CREATE OR REPLACE VIEW vw_fact_sales AS
SELECT
    f.item_id,
    f.sale_id,
    f.sale_date,
    f.channel,

    c.country,
    c.age_range,

    p.product_name,
    p.category,
    p.brand,

    cp.campaign_name,

    f.quantity,
    f.unit_price,
    f.discount_applied,
    f.item_total,
    f.total_amount

FROM gold_fact_sales f
LEFT JOIN gold_dim_customer c ON f.customer_key = c.customer_key
LEFT JOIN gold_dim_product p ON f.product_key = p.product_key
LEFT JOIN gold_dim_campaign cp ON f.campaign_key = cp.campaign_key;



