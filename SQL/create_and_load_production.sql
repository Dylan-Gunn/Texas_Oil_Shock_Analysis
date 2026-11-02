PRAGMA table_info(stg_texas_crude);
SELECT * FROM stg_texas_crude LIMIT 10;


-- Creating the production table
DROP TABLE IF EXISTS production;

CREATE TABLE production (
    prod_month  TEXT NOT NULL,   
    region      TEXT NOT NULL,  
    product     TEXT NOT NULL,   
    value       REAL,
    unit        TEXT,           
    PRIMARY KEY (prod_month, region, product)
);

-- importing data from each staging tables
INSERT INTO production (prod_month, region, product, value, unit)
SELECT
    substr(eia_date, 5, 4) || '-' ||
    CASE substr(eia_date, 1, 3)
        WHEN 'Jan' THEN '01' WHEN 'Feb' THEN '02' WHEN 'Mar' THEN '03'
        WHEN 'Apr' THEN '04' WHEN 'May' THEN '05' WHEN 'Jun' THEN '06'
        WHEN 'Jul' THEN '07' WHEN 'Aug' THEN '08' WHEN 'Sep' THEN '09'
        WHEN 'Oct' THEN '10' WHEN 'Nov' THEN '11' WHEN 'Dec' THEN '12'
    END || '-01',
    'texas',
    'crude_oil',
    CASE WHEN TRIM(eia_value) = '' THEN NULL ELSE CAST(eia_value AS REAL) END,
    'thousand barrels per month'
FROM stg_texas_crude
WHERE length(eia_date) = 8
  AND substr(eia_date, 5, 4) >= '2025';
  
 
ALTER TABLE stg_us_crude RENAME COLUMN "Back to Contents" TO eia_date;
ALTER TABLE stg_us_crude RENAME COLUMN "Data 1: U.S. Field Production of Crude Oil (Thousand Barrels)" TO eia_value;
 
INSERT INTO production (prod_month, region, product, value, unit)
SELECT
    substr(eia_date, 5, 4) || '-' ||
    CASE substr(eia_date, 1, 3)
        WHEN 'Jan' THEN '01' WHEN 'Feb' THEN '02' WHEN 'Mar' THEN '03'
        WHEN 'Apr' THEN '04' WHEN 'May' THEN '05' WHEN 'Jun' THEN '06'
        WHEN 'Jul' THEN '07' WHEN 'Aug' THEN '08' WHEN 'Sep' THEN '09'
        WHEN 'Oct' THEN '10' WHEN 'Nov' THEN '11' WHEN 'Dec' THEN '12'
    END || '-01',
    'us',
    'crude_oil',
    CASE WHEN TRIM(eia_value) = '' THEN NULL ELSE CAST(eia_value AS REAL) END,
    'thousand barrels per month'
FROM stg_us_crude
WHERE length(eia_date) = 8
  AND substr(eia_date, 5, 4) >= '2025';
  
  
ALTER TABLE stg_us_natgas RENAME COLUMN "Back to Contents" TO eia_date;
ALTER TABLE stg_us_natgas RENAME COLUMN "Data 1: U.S. Natural Gas Gross Withdrawals (MMcf)" TO eia_value;

INSERT INTO production (prod_month, region, product, value, unit)
SELECT
    substr(eia_date, 5, 4) || '-' ||
    CASE substr(eia_date, 1, 3)
        WHEN 'Jan' THEN '01' WHEN 'Feb' THEN '02' WHEN 'Mar' THEN '03'
        WHEN 'Apr' THEN '04' WHEN 'May' THEN '05' WHEN 'Jun' THEN '06'
        WHEN 'Jul' THEN '07' WHEN 'Aug' THEN '08' WHEN 'Sep' THEN '09'
        WHEN 'Oct' THEN '10' WHEN 'Nov' THEN '11' WHEN 'Dec' THEN '12'
    END || '-01',
    'us',
    'natural_gas',
    CASE WHEN TRIM(eia_value) = '' THEN NULL ELSE CAST(eia_value AS REAL) END,
    'MMcf'
FROM stg_us_natgas
WHERE length(eia_date) = 8
  AND substr(eia_date, 5, 4) >= '2025';
  

ALTER TABLE stg_texas_natgas RENAME COLUMN "Back to Contents" TO eia_date;
ALTER TABLE stg_texas_natgas RENAME COLUMN "Data 1: Texas Natural Gas Gross Withdrawals (MMcf)" TO eia_value;

INSERT INTO production (prod_month, region, product, value, unit)
SELECT
    substr(eia_date, 5, 4) || '-' ||
    CASE substr(eia_date, 1, 3)
        WHEN 'Jan' THEN '01' WHEN 'Feb' THEN '02' WHEN 'Mar' THEN '03'
        WHEN 'Apr' THEN '04' WHEN 'May' THEN '05' WHEN 'Jun' THEN '06'
        WHEN 'Jul' THEN '07' WHEN 'Aug' THEN '08' WHEN 'Sep' THEN '09'
        WHEN 'Oct' THEN '10' WHEN 'Nov' THEN '11' WHEN 'Dec' THEN '12'
    END || '-01',
    'texas',
    'natural_gas',
    CASE WHEN TRIM(eia_value) = '' THEN NULL ELSE CAST(eia_value AS REAL) END,
    'MMcf'
FROM stg_texas_natgas
WHERE length(eia_date) = 8
  AND substr(eia_date, 5, 4) >= '2025';

-- Verifying data
SELECT region, product, COUNT(*) AS n_rows,
       MIN(prod_month) AS first_month, MAX(prod_month) AS last_month,
       SUM(value IS NULL) AS n_missing
FROM production
GROUP BY region, product;