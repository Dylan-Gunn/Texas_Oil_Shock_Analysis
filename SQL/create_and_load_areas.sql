SELECT area_fips, own_code, industry_code, disclosure_code, annual_avg_emplvl
FROM stg_211
WHERE area_fips IN ('48329', '48135', '48389', '48453')
ORDER BY area_fips, own_code;

SELECT DISTINCT year, qtr FROM stg_211;

DROP TABLE IF EXISTS county_employment;

CREATE TABLE county_employment (
    area_fips      TEXT PRIMARY KEY,
    oil_gas_emp    INTEGER,
    total_emp      INTEGER,
    oil_share_pct  REAL,
    any_suppressed INTEGER
);

WITH oil_rows AS (
    SELECT area_fips, annual_avg_emplvl AS emp, disclosure_code
    FROM stg_211
    WHERE own_code = '5' AND area_fips LIKE '48%'
    UNION ALL
    SELECT area_fips, annual_avg_emplvl, disclosure_code
    FROM stg_213111
    WHERE own_code = '5' AND area_fips LIKE '48%'
    UNION ALL
    SELECT area_fips, annual_avg_emplvl, disclosure_code
    FROM stg_213112
    WHERE own_code = '5' AND area_fips LIKE '48%'
),
oil_sum AS (
    SELECT area_fips,
           SUM(emp) AS oil_gas_emp,
           MAX(CASE WHEN disclosure_code = 'N' THEN 1 ELSE 0 END) AS any_suppressed
    FROM oil_rows
    GROUP BY area_fips
),
total AS (
    SELECT area_fips, annual_avg_emplvl AS total_emp
    FROM stg_10
    WHERE own_code = '5'
      AND area_fips LIKE '48%'
      AND area_fips NOT IN ('48000', '48999')
)
INSERT INTO county_employment
SELECT t.area_fips,
       COALESCE(o.oil_gas_emp, 0),
       t.total_emp,
       ROUND(100.0 * COALESCE(o.oil_gas_emp, 0) / t.total_emp, 2),
       COALESCE(o.any_suppressed, 0)
FROM total t
LEFT JOIN oil_sum o ON o.area_fips = t.area_fips;

SELECT area_fips, oil_gas_emp, total_emp, oil_share_pct, any_suppressed
FROM county_employment
WHERE total_emp >= 1000
ORDER BY oil_share_pct DESC
LIMIT 15;

DROP TABLE IF EXISTS areas;

CREATE TABLE areas (
    area_fips   TEXT PRIMARY KEY,
    area_name   TEXT,
    area_group  TEXT NOT NULL CHECK (area_group IN ('oil_heavy', 'comparison')),
    group_rule  TEXT
);

-- Finding oil heavy counties 
INSERT INTO areas (area_fips, area_group, group_rule)
SELECT area_fips, 'oil_heavy', 'oil share >= 15% and total emp >= 1000, 2025'
FROM county_employment
WHERE oil_share_pct >= 5 AND total_emp >= 1000 AND any_suppressed = 0;

-- looking for supressed counties that are oil heavy
SELECT area_fips, total_emp, any_suppressed, oil_share_pct
FROM county_employment
WHERE area_fips IN ('48329', '48389', '48461');

-- Adding supressed counties to the area table
ALTER TABLE areas ADD COLUMN inclusion_basis TEXT;

-- Updating exisitng table entries 
UPDATE areas
SET inclusion_basis = 'oil_share_5pct'
WHERE inclusion_basis IS NULL;

-- Inserting supressed counties into area table
INSERT INTO areas (area_fips, area_name, area_group, group_rule, inclusion_basis)
VALUES
    ('48461', 'County A', 'oil_heavy',
     'employment suppressed; included via [your fallback rule]', 'fallback'),
    ('48329', 'County B', 'oil_heavy',
     'employment suppressed; included via [your fallback rule]', 'fallback'),
    ('48389', 'County C', 'oil_heavy',
     'employment suppressed; included via [your fallback rule]', 'fallback');
	 
-- Updating county names in area table
UPDATE areas SET area_name = 'Coleman' WHERE area_fips = '48083';
UPDATE areas SET area_name = 'Ector' WHERE area_fips = '48135';
UPDATE areas SET area_name = 'Gray' WHERE area_fips = '48179';
UPDATE areas SET area_name = 'Upton' WHERE area_fips = '48461';
UPDATE areas SET area_name = 'Midland' WHERE area_fips = '48329';
UPDATE areas SET area_name = 'Reeves' WHERE area_fips = '48389';

-- Finding non-oil heavy counties for comparison
SELECT area_fips, oil_gas_emp, total_emp, oil_share_pct
FROM county_employment
WHERE any_suppressed = 0
  AND oil_share_pct < 1   
  AND total_emp >= 1000   
ORDER BY total_emp DESC;

-- Adding non-oil heavy counties
INSERT INTO areas (area_fips, group_rule, area_group, inclusion_basis)
SELECT area_fips,
       'oil share < 1%; shortlisted for size and Comptroller data coverage',
       'comparison',
       'low_oil_share_shortlist'
FROM county_employment
WHERE area_fips IN ('48117', '48023', '48411', '48453', '48085', '48425');

-- Adding county names to non-oil
UPDATE areas SET area_name = 'Travis' WHERE area_fips = '48453';
UPDATE areas SET area_name = 'Collin' WHERE area_fips = '48085';
UPDATE areas SET area_name = 'Deaf Smith' WHERE area_fips = '48117';
UPDATE areas SET area_name = 'Baylor' WHERE area_fips = '48023';
UPDATE areas SET area_name = 'Somervell' WHERE area_fips = '48425';
UPDATE areas SET area_name = 'San Saba' WHERE area_fips = '48411';

-- Double checking table values for missing information or duplicates
SELECT a.area_fips, a.area_name, a.area_group, a.inclusion_basis,
       c.total_emp, c.oil_share_pct
FROM areas a
LEFT JOIN county_employment c ON c.area_fips = a.area_fips
ORDER BY a.area_group, c.total_emp DESC;