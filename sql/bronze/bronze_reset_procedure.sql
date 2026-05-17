-- ============================================
-- SCRIPT: bronze_reset_procedure.sql
-- PURPOSE:
-- This stored procedure resets all Bronze tables by truncating them.
-- It ensures clean data reload for every pipeline execution.
-- ============================================

USE datawarehouse;

DELIMITER $$

CREATE PROCEDURE bronze_load_bronze()
BEGIN

    TRUNCATE TABLE bronze_sales;
    TRUNCATE TABLE bronze_sales_items;
    TRUNCATE TABLE bronze_products;
    TRUNCATE TABLE bronze_customers;
    TRUNCATE TABLE bronze_stock;
    TRUNCATE TABLE bronze_channels;
    TRUNCATE TABLE bronze_campaigns;

END $$

DELIMITER ;
