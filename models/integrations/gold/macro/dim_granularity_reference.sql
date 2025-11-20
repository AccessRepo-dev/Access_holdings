SELECT 'place_id, hpi_flavor, hpi_type,level, DateKey,frequency' AS GranularityColumns,
    'hash(place_id, hpi_flavor, hpi_type,level, DateKey,frequency)' AS GrainLogic,
    'HOUSING' AS DATASET,
    'Federal Housing Finance Agency' AS DATASOURCE

UNION ALL

SELECT 'DateKey',
    'hash(DateKey)',
    'Housing' AS DATASET,
    'National Association of Home Builders' AS DATASOURCE

UNION ALL

SELECT 'series_id, DateKey',
    'hash(series_id, DateKey)',
    'Producer Price Index' AS DATASET,
    'Bureau of Labor Statistics' AS DATASOURCE

UNION ALL

SELECT 'series_id, DateKey',
    'hash(series_id, DateKey)',
    'Consumer Price Index' AS DATASET,
    'Bureau of Labor Statistics' AS DATASOURCE

UNION ALL

SELECT 'series_id, DateKey',
    'hash(series_id, DateKey)', 
    'Transport' AS DATASET,
    'Bureau of Transportation' AS DATASOURCE

UNION ALL

SELECT 'series_id, DateKey',
    'hash(series_id, DateKey)',
    'Employment' AS DATASET,
    'Bureau of Labor Statistics' AS DATASOURCE

UNION ALL

SELECT 'series_id, DateKey',
    'hash(series_id, DateKey)',
    'Unemployment' AS DATASET,
    'Bureau of Labor Statistics' AS DATASOURCE

UNION ALL

SELECT 'series_id, DateKey',
    'hash(series_id, DateKey)',
    'Consumer' AS DATASET,
    'Umich Survey of Consumers' AS DATASOURCE

UNION ALL

SELECT 'Industry, TableID, IndustryDescription, DATEKEY',
    'hash(Industry, TableID, IndustryDescription, DATEKEY)',
    'GDP Industry' AS DATASET,
    'Bureau of Economic Analysis' AS DATASOURCE

UNION ALL

SELECT 'SERIESCODE, DATEKEY',
    'hash(SERIESCODE, DATEKEY)',
    'GDP Nominal' AS DATASET,
    'Bureau of Economic Analysis' AS DATASOURCE

UNION ALL

SELECT 'TABLENAME, SERIESCODE, LINEDESCRIPTION, DATEKEY',
    'hash(TABLENAME, SERIESCODE, LINEDESCRIPTION, DATEKEY)',
    'GDP Real' AS DATASET,
    'Bureau of Economic Analysis' AS DATASOURCE

UNION ALL

SELECT 'GEONAME, DATEKEY',
    'hash(GEONAME, DATEKEY)',
    'GDP Region' AS DATASET,
    'Bureau of Economic Analysis' AS DATASOURCE

UNION ALL

SELECT 'agg_ris, category,Date',
    'hash(agg_ris, category,Date)',
    'EMPLOYEMENT' AS DATASET,
    'ADP' AS DATASOURCE

UNION ALL

SELECT 'category,datekey',
    'hash(category,datekey)' ,
    'PAYINSIGHTS' AS DATASET,
    'ADP' AS DATASOURCE

UNION ALL

SELECT 'DateKey',
    'hash(DateKey)',
    'Housing_starts' AS DATASET,
    'Census' AS DATASOURCE

UNION ALL

SELECT 'DateKey',
    'hash(DateKey)',
    'Housing_completed' AS DATASET,
    'Census' AS DATASOURCE

UNION ALL

SELECT 'SERIES_ID, DateKey',
    'hash(SERIES_ID, DateKey)',
    'FRED' AS DATASET,
    'Federal Reserve Economic Data' AS DATASOURCE
