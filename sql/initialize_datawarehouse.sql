-- ============================================
-- SCRIPT: initialize_datawarehouse.sql
-- PURPOSE:
-- This script initializes the data warehouse environment.
-- It ensures a clean and reproducible setup by dropping
-- and recreating the database before pipeline execution.
-- ============================================

DROP DATABASE IF EXISTS datawarehouse;

CREATE DATABASE datawarehouse;

USE datawarehouse;