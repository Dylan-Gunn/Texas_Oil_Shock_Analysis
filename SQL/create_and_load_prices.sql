DROP TABLE IF EXISTS prices;

CREATE TABLE prices (
	price_date TEXT NOT NULL,
	series     TEXT NOT NULL,
	value      REAL,
	unit       TEXT,
	PRIMARY KEY (price_date, series)
);

INSERT INTO prices (price_date, series, value, unit)
SELECT
	observation_date,
	'brent',
	CASE WHEN TRIM(DCOILBRENTEU) IN ('', '.') THEN NULL	
		ELSE CAST(DCOILBRENTEU AS REAL) END,
	'USD per barrel'
FROM stg_brent
WHERE observation_date >= '2025-01-01';

SELECT series,
	COUNT(*)				AS n_rows,
	SUM(value IS NULL)      AS n_missing,
	MIN(price_date)         AS first_date,
	MAX(price_date)         AS last_date
FROM prices
GROUP BY series;

INSERT INTO prices (price_date, series, value, unit)
SELECT
	observation_date,
	'wti',
	CASE WHEN TRIM(DCOILWTICO) IN ('', '.') THEN NULL	
		ELSE CAST(DCOILWTICO AS REAL) END,
	'USD per barrel'
FROM stg_wti
WHERE observation_date >= '2025-01-01';

INSERT INTO prices (price_date, series, value, unit)
SELECT
	observation_date,
	'gasoline_regular',
	CASE WHEN TRIM(GASREGW) IN ('', '.') THEN NULL	
		ELSE CAST(GASREGW AS REAL) END,
	'USD per gallon'
FROM stg_gasoline
WHERE observation_date >= '2025-01-01';

INSERT INTO prices (price_date, series, value, unit)
SELECT
	observation_date,
	'diesel',
	CASE WHEN TRIM(GASDESW) IN ('', '.') THEN NULL	
		ELSE CAST(GASDESW AS REAL) END,
	'USD per gallon'
FROM stg_diesel
WHERE observation_date >= '2025-01-01';

INSERT INTO prices (price_date, series, value, unit)
SELECT
	observation_date,
	'henryhub',
	CASE WHEN TRIM(DHHNGSP) IN ('', '.') THEN NULL	
		ELSE CAST(DHHNGSP AS REAL) END,
	'USD per MMBtu'
FROM stg_henryhub
WHERE observation_date >= '2025-01-01';

