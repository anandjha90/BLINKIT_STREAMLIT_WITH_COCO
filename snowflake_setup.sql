-- ============================================================
-- Snowflake Setup Script for Blinkit Analytics Dashboard
-- Run this script in Snowflake to create the database, schema,
-- tables, and load synthetic data.
-- ============================================================

USE ROLE ACCOUNTADMIN;
CREATE WAREHOUSE IF NOT EXISTS COMPUTE_WH WAREHOUSE_SIZE = 'XSMALL' AUTO_SUSPEND = 60 AUTO_RESUME = TRUE;
USE WAREHOUSE COMPUTE_WH;

-- Database & Schema
CREATE DATABASE IF NOT EXISTS BLINKIT_DW;
USE DATABASE BLINKIT_DW;
CREATE SCHEMA IF NOT EXISTS RAW;
USE SCHEMA RAW;

-- ============================================================
-- Table 1: BLINKIT_ORDERS
-- ============================================================
CREATE TABLE IF NOT EXISTS BLINKIT_ORDERS (
    ORDER_ID         NUMBER(12,0) NOT NULL PRIMARY KEY,
    CUSTOMER_ID      NUMBER(12,0),
    ORDER_DATE       TIMESTAMP_NTZ(9),
    PROMISED_DELIVERY_TIME TIMESTAMP_NTZ(9),
    ACTUAL_DELIVERY_TIME   TIMESTAMP_NTZ(9),
    DELIVERY_STATUS  VARCHAR(50),
    ORDER_TOTAL      NUMBER(10,2),
    PAYMENT_METHOD   VARCHAR(50),
    DELIVERY_PARTNER_ID NUMBER(12,0),
    STORE_ID         NUMBER(12,0)
);

-- ============================================================
-- Table 2: BLINKIT_DELIVERY_PERFORMANCE
-- ============================================================
CREATE TABLE IF NOT EXISTS BLINKIT_DELIVERY_PERFORMANCE (
    ORDER_ID             NUMBER(12,0) NOT NULL PRIMARY KEY,
    DELIVERY_PARTNER_ID  NUMBER(12,0),
    PROMISED_TIME        TIMESTAMP_NTZ(9),
    ACTUAL_TIME          TIMESTAMP_NTZ(9),
    DELIVERY_TIME_MINUTES NUMBER(6,2) AS (DATEDIFF('MINUTE', PROMISED_TIME, ACTUAL_TIME)),
    DISTANCE_KM          NUMBER(6,2),
    DELIVERY_STATUS      VARCHAR(50),
    REASONS_IF_DELAYED   VARCHAR(200)
);

-- ============================================================
-- Table 3: BLINKIT_ORDER_ITEMS
-- ============================================================
CREATE TABLE IF NOT EXISTS BLINKIT_ORDER_ITEMS (
    ORDER_ID    NUMBER(12,0) NOT NULL,
    PRODUCT_ID  NUMBER(12,0) NOT NULL,
    QUANTITY    NUMBER(10,0),
    UNIT_PRICE  NUMBER(10,2),
    TOTAL_PRICE NUMBER(12,2) AS (QUANTITY * UNIT_PRICE),
    PRIMARY KEY (ORDER_ID, PRODUCT_ID)
);

-- ============================================================
-- Table 4: BLINKIT_MARKETING_PERFORMANCE
-- ============================================================
CREATE TABLE IF NOT EXISTS BLINKIT_MARKETING_PERFORMANCE (
    CAMPAIGN_ID       NUMBER(12,0),
    CAMPAIGN_NAME     VARCHAR(100),
    DATE              DATE,
    TARGET_AUDIENCE   VARCHAR(50),
    CHANNEL           VARCHAR(50),
    IMPRESSIONS       NUMBER(10,0),
    CLICKS            NUMBER(10,0),
    CONVERSIONS       NUMBER(10,0),
    SPEND             NUMBER(12,2),
    REVENUE_GENERATED NUMBER(12,2),
    ROAS              NUMBER(6,2)
);

-- ============================================================
-- Synthetic Data: BLINKIT_ORDERS (5000 rows)
-- ============================================================
INSERT INTO BLINKIT_ORDERS (ORDER_ID, CUSTOMER_ID, ORDER_DATE, PROMISED_DELIVERY_TIME, ACTUAL_DELIVERY_TIME, DELIVERY_STATUS, ORDER_TOTAL, PAYMENT_METHOD, DELIVERY_PARTNER_ID, STORE_ID)
SELECT
    ABS(RANDOM()) AS ORDER_ID,
    UNIFORM(1000000, 99999999, RANDOM()) AS CUSTOMER_ID,
    DATEADD('MINUTE', UNIFORM(0, 525600, RANDOM()), '2023-10-01'::TIMESTAMP) AS ORDER_DATE,
    DATEADD('MINUTE', UNIFORM(10, 30, RANDOM()), ORDER_DATE) AS PROMISED_DELIVERY_TIME,
    DATEADD('MINUTE', UNIFORM(-5, 15, RANDOM()), PROMISED_DELIVERY_TIME) AS ACTUAL_DELIVERY_TIME,
    CASE UNIFORM(1, 10, RANDOM())
        WHEN 1 THEN 'Delayed'
        WHEN 2 THEN 'Cancelled'
        ELSE 'On Time'
    END AS DELIVERY_STATUS,
    ROUND(UNIFORM(50.0::FLOAT, 5000.0::FLOAT, RANDOM()), 2) AS ORDER_TOTAL,
    CASE UNIFORM(1, 3, RANDOM()) WHEN 1 THEN 'Cash' WHEN 2 THEN 'UPI' ELSE 'Card' END AS PAYMENT_METHOD,
    UNIFORM(10000, 99999, RANDOM()) AS DELIVERY_PARTNER_ID,
    UNIFORM(1000, 9999, RANDOM()) AS STORE_ID
FROM TABLE(GENERATOR(ROWCOUNT => 5000));

-- ============================================================
-- Synthetic Data: BLINKIT_DELIVERY_PERFORMANCE (1000 rows)
-- ============================================================
INSERT INTO BLINKIT_DELIVERY_PERFORMANCE (ORDER_ID, DELIVERY_PARTNER_ID, PROMISED_TIME, ACTUAL_TIME, DISTANCE_KM, DELIVERY_STATUS, REASONS_IF_DELAYED)
WITH order_base AS (
    SELECT ORDER_ID, DELIVERY_PARTNER_ID, PROMISED_DELIVERY_TIME AS PROMISED_TIME,
           ACTUAL_DELIVERY_TIME AS ACTUAL_TIME, DELIVERY_STATUS
    FROM BLINKIT_ORDERS SAMPLE (1000 ROWS)
)
SELECT ORDER_ID, DELIVERY_PARTNER_ID, PROMISED_TIME, ACTUAL_TIME,
    ROUND(UNIFORM(0.5::FLOAT, 12.0::FLOAT, RANDOM()), 2) AS DISTANCE_KM,
    DELIVERY_STATUS,
    CASE
        WHEN DELIVERY_STATUS = 'Delayed' THEN
            CASE UNIFORM(1, 5, RANDOM())
                WHEN 1 THEN 'Heavy traffic congestion'
                WHEN 2 THEN 'Incorrect address provided'
                WHEN 3 THEN 'Order preparation delay at store'
                WHEN 4 THEN 'Delivery partner vehicle breakdown'
                WHEN 5 THEN 'Weather conditions - heavy rain'
            END
        WHEN DELIVERY_STATUS = 'Cancelled' THEN
            CASE UNIFORM(1, 3, RANDOM())
                WHEN 1 THEN 'Customer cancelled order'
                WHEN 2 THEN 'Store out of stock'
                WHEN 3 THEN 'Payment failure'
            END
        ELSE NULL
    END AS REASONS_IF_DELAYED
FROM order_base;

-- ============================================================
-- Synthetic Data: BLINKIT_ORDER_ITEMS (1000 rows)
-- ============================================================
INSERT INTO BLINKIT_ORDER_ITEMS (ORDER_ID, PRODUCT_ID, QUANTITY, UNIT_PRICE)
WITH order_ids AS (
    SELECT ORDER_ID FROM BLINKIT_ORDERS SAMPLE (1000 ROWS)
)
SELECT ORDER_ID,
    UNIFORM(100001, 199999, RANDOM()) AS PRODUCT_ID,
    UNIFORM(1, 6, RANDOM()) AS QUANTITY,
    ROUND(CASE UNIFORM(1, 5, RANDOM())
        WHEN 1 THEN UNIFORM(10.0::FLOAT, 50.0::FLOAT, RANDOM())
        WHEN 2 THEN UNIFORM(50.0::FLOAT, 150.0::FLOAT, RANDOM())
        WHEN 3 THEN UNIFORM(150.0::FLOAT, 500.0::FLOAT, RANDOM())
        WHEN 4 THEN UNIFORM(500.0::FLOAT, 1500.0::FLOAT, RANDOM())
        WHEN 5 THEN UNIFORM(15.0::FLOAT, 99.0::FLOAT, RANDOM())
    END, 2) AS UNIT_PRICE
FROM order_ids;

-- ============================================================
-- Synthetic Data: BLINKIT_MARKETING_PERFORMANCE (5400 rows)
-- ============================================================
INSERT INTO BLINKIT_MARKETING_PERFORMANCE (CAMPAIGN_ID, CAMPAIGN_NAME, DATE, TARGET_AUDIENCE, CHANNEL, IMPRESSIONS, CLICKS, CONVERSIONS, SPEND, REVENUE_GENERATED, ROAS)
SELECT
    UNIFORM(100000, 999999, RANDOM()) AS CAMPAIGN_ID,
    CASE UNIFORM(1, 6, RANDOM())
        WHEN 1 THEN 'New User Discount'
        WHEN 2 THEN 'Weekend Special'
        WHEN 3 THEN 'Festival Offer'
        WHEN 4 THEN 'Flash Sale'
        WHEN 5 THEN 'Membership Drive'
        WHEN 6 THEN 'Referral Bonus'
    END AS CAMPAIGN_NAME,
    DATEADD('DAY', UNIFORM(0, 365, RANDOM()), '2024-01-01')::DATE AS DATE,
    CASE UNIFORM(1, 4, RANDOM())
        WHEN 1 THEN 'New Users'
        WHEN 2 THEN 'Premium'
        WHEN 3 THEN 'Inactive'
        WHEN 4 THEN 'Regular'
    END AS TARGET_AUDIENCE,
    CASE UNIFORM(1, 3, RANDOM()) WHEN 1 THEN 'App' WHEN 2 THEN 'Email' ELSE 'SMS' END AS CHANNEL,
    UNIFORM(500, 10000, RANDOM()) AS IMPRESSIONS,
    UNIFORM(50, 1000, RANDOM()) AS CLICKS,
    UNIFORM(10, 200, RANDOM()) AS CONVERSIONS,
    ROUND(UNIFORM(500.0::FLOAT, 10000.0::FLOAT, RANDOM()), 2) AS SPEND,
    ROUND(UNIFORM(1000.0::FLOAT, 15000.0::FLOAT, RANDOM()), 2) AS REVENUE_GENERATED,
    ROUND(UNIFORM(1.0::FLOAT, 5.0::FLOAT, RANDOM()), 2) AS ROAS
FROM TABLE(GENERATOR(ROWCOUNT => 5400));
