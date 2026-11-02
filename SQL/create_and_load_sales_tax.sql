SELECT * FROM stg_sales_tax LIMIT 10;
PRAGMA table_info(stg_sales_tax);

-- 1. What kinds of rows exist?
SELECT "Report Period Type", COUNT(*)
FROM stg_sales_tax
GROUP BY "Report Period Type";

-- 2. Date range
SELECT MIN("Report Year"), MAX("Report Year"), COUNT(*)
FROM stg_sales_tax;

-- 3. Latest months available
SELECT DISTINCT "Report Year", "Report Month"
FROM stg_sales_tax
WHERE "Report Year" >= 2026
ORDER BY "Report Year", "Report Month";

-- 4. How an oil area appears
SELECT "County", "City", "Report Year", "Report Month",
       "Report Period Type", "Net Payment This Period"
FROM stg_sales_tax
WHERE "County" LIKE '%Midland%'
ORDER BY "Report Year" DESC, "Report Month" DESC
LIMIT 15;

-- Changing text to integer for payments
SELECT "County", "City", "Report Year", "Report Month",
       "Net Payment This Period" AS original_text,
       CAST(REPLACE(REPLACE("Net Payment This Period", '$', ''), ',', '') AS REAL) AS payment_clean
FROM stg_sales_tax
WHERE "County" = 'Midland'
LIMIT 10;

-- 1. What rows exist for Midland County in one month? Looking for county-level or unincorporated rows
SELECT "City", "Net Payment This Period"
FROM stg_sales_tax
WHERE "County" = 'Midland' AND "Report Year" = 2026 AND "Report Month" = 6
  AND "Report Period Type" = 'MONTHLY';

-- 2. All period types
SELECT "Report Period Type", COUNT(*) FROM stg_sales_tax GROUP BY 1;

-- 3. Any odd money formats (negatives, blanks)?
SELECT "Net Payment This Period" FROM stg_sales_tax
WHERE "Net Payment This Period" LIKE '%(%' OR "Net Payment This Period" LIKE '%-%'
   OR TRIM("Net Payment This Period") = ''
LIMIT 10;

-- 4. Are all your counties present, and for how many months?
SELECT "County", COUNT(DISTINCT "Report Year" * 100 + "Report Month") AS months
FROM stg_sales_tax
WHERE "Report Year" >= 2025
GROUP BY "County"
ORDER BY months;

-- Midland County rows in one month: are there only city rows, or also county-level rows?
SELECT "City", "Net Payment This Period"
FROM stg_sales_tax
WHERE "County" = 'Midland' AND "Report Year" = 2026 AND "Report Month" = 6
  AND "Report Period Type" = 'MONTHLY';

-- All period types
SELECT "Report Period Type", COUNT(*) FROM stg_sales_tax GROUP BY 1;

-- Checking for duplicates
SELECT "County", "City", "Report Year", "Report Month", COUNT(*) AS n
FROM stg_sales_tax
WHERE "Report Period Type" = 'MONTHLY' AND "Report Year" >= 2025
GROUP BY 1, 2, 3, 4
HAVING COUNT(*) > 1
LIMIT 10;

-- Creating the table for sales tax
DROP TABLE IF EXISTS sales_tax;

CREATE TABLE sales_tax (
    county                 TEXT NOT NULL,
    city                   TEXT NOT NULL,
    report_month           TEXT NOT NULL,  
    net_payment            REAL,           
    comparable_prior_year  REAL,          
    PRIMARY KEY (county, city, report_month)
);

-- Loading data from stg_sales_tax into sales table
INSERT INTO sales_tax (county, city, report_month, net_payment, comparable_prior_year)
SELECT
    "County",
    "City",
    "Report Year" || '-' || printf('%02d', "Report Month") || '-01',
    CASE
        WHEN TRIM("Net Payment This Period") = '' THEN NULL
        WHEN "Net Payment This Period" LIKE '(%' THEN
            -CAST(REPLACE(REPLACE(REPLACE(REPLACE("Net Payment This Period",'$',''),',',''),'(',''),')','') AS REAL)
        ELSE CAST(REPLACE(REPLACE("Net Payment This Period",'$',''),',','') AS REAL)
    END,
    CASE
        WHEN TRIM("Comparable Payment Prior Year") = '' THEN NULL
        WHEN "Comparable Payment Prior Year" LIKE '(%' THEN
            -CAST(REPLACE(REPLACE(REPLACE(REPLACE("Comparable Payment Prior Year",'$',''),',',''),'(',''),')','') AS REAL)
        ELSE CAST(REPLACE(REPLACE("Comparable Payment Prior Year",'$',''),',','') AS REAL)
    END
FROM stg_sales_tax
WHERE "Report Period Type" = 'MONTHLY'
  AND "Report Year" >= 2025;
  
  