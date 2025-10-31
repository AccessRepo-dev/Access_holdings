{% macro get_dataset_config() %}
    {% set datasets = [
        {
            'id': 1,
            'name': 'fhfa_housing',
            'dataset': 'HOUSING',
            'datasource': 'FHFA',
            'measures': "'index_nsa, index_sa'",
            'unpivot': true,
            'granularity_id': 'place_id, hpi_flavor, hpi_type'
        },
        {
            'id': 2,
            'name': 'nahb_housing',
            'dataset': 'HOUSING',
            'datasource': 'National Association of Home Builders',
            'measures': "'HMI'",
            'unpivot': true,
            'granularity_id': ''
        },
        {
            'id': 3,
            'name': 'bls_ppi',
            'dataset': 'Producer Price Index',
            'datasource': 'Bureau of Labor Statistics',
            'where': "series_id IN ('WPUFD4','WPUFD4L1T15','WPUFD4131','WPUFD41302','WPUFD41303','WPU05','WPU02','WPU301')",
            'unpivot': false,
            'measures': "'WPUFD4','WPUFD4L1T15','WPUFD4131','WPUFD41302','WPUFD41303','WPU05','WPU02','WPU301'",
            'granularity_id': 'series_id'
        },
        {
            'id': 4,
            'name': 'bls_cpi',
            'dataset': 'Consumer Price Index',
            'datasource': 'Bureau of Labor Statistics',
            'where': "SERIES_ID IN ('CUUR0000SA0','CUUR0000SA0L1E','CUUR0000SAF1','CUUR0000SAF11','CUUR0000SEFV','CUUR0000SA0E','CUUR0000SEHA','CUUR0000SETA01','CUUR0000SETA02','CUUR0000SAM','CUUR0000SAF','CUUR0000SETB01')",
            'unpivot': false,
            'measures': "'CUUR0000SA0','CUUR0000SA0L1E','CUUR0000SAF1','CUUR0000SAF11','CUUR0000SEFV','CUUR0000SA0E','CUUR0000SEHA','CUUR0000SETA01','CUUR0000SETA02','CUUR0000SAM','CUUR0000SAF','CUUR0000SETB01'",
            'granularity_id': 'series_id'
        },
        {
            'id': 5,
            'name': 'bot_transport_index',
            'dataset': 'Transport',
            'datasource': 'Bureau of Transportation',
            'where': "SERIES_TITLE in ('Air Revenue Passenger Miles (Transportation Services Index)','Air Revenue Ton Miles of Freight and Mail','Airline Load Factor (RPM/ASM)','Available Seat Miles','Enplanements (Boardings)','Indexed Rail Freight Carloads','Indexed Rail Freight Intermodal','Industrial Production Index','International Airline Load Factor','International Enplanements','Inventory to Sales Ratio','Manufacturing Output Index','Natural Gas Transport Volume','Petroleum Transport Volume','Public Transit Ridership','Rail Freight Carloads','Rail Passenger Miles','Revenue Passenger Miles','Transportation Services Index - Freight','Transportation Services Index - Passenger','Transportation Services Index - Total','Vehicle Miles Traveled','Waterborne Freight Volume')",
            'unpivot': false,
            'measures': "Air Revenue Passenger Miles (Transportation Services Index)','Air Revenue Ton Miles of Freight and Mail','Airline Load Factor (RPM/ASM)','Available Seat Miles','Enplanements (Boardings)','Indexed Rail Freight Carloads','Indexed Rail Freight Intermodal','Industrial Production Index','International Airline Load Factor','International Enplanements','Inventory to Sales Ratio','Manufacturing Output Index','Natural Gas Transport Volume','Petroleum Transport Volume','Public Transit Ridership','Rail Freight Carloads','Rail Passenger Miles','Revenue Passenger Miles','Transportation Services Index - Freight','Transportation Services Index - Passenger','Transportation Services Index - Total','Vehicle Miles Traveled','Waterborne Freight Volume",
            'granularity_id': 'series_id'
        },
        {
            'id': 6,
            'name': 'umich_sent',
            'dataset': 'Consumer',
            'datasource': 'Umich Survey of Consumers',
            'unpivot': false,
            'measure_name': 'SERIES_TITLE',
            'granularity_id': 'series_id'
        },
        {
            'id': 7,
            'name': 'bea_gdp_industry',
            'dataset': 'GDP',
            'datasource': 'Bureau of Economic Analysis',
            'unpivot': false,
            'measure_name': "'Value Added by Industry'",
            'measure_value': 'DataValue / 12',
            'granularity_id': 'Industry, TableID, IndustryDescription',
           
        },
        {
            'id': 8,
            'name': 'bea_gdp_nominal',
            'dataset': 'GDP',
            'datasource': 'Bureau of Economic Analysis',
            'where': "SERIESCODE = 'A191RC'",
            'unpivot': false,
            'measure_name': "'GDP (Nominal)'",
            'measure_value': 'B.DATAVALUE / 3',
            'granularity_id': 'TABLENAME',
            'join': "LEFT JOIN {{ ref('dim_date_monthly') }} D ON LEFT(B.TIMEPERIOD, 4) = D.YEAR AND RIGHT(B.TIMEPERIOD, 2) = D.QUARTER_NAME"
        },
        {
            'id': 9,
            'name': 'bea_gdp_real',
            'dataset': 'GDP',
            'datasource': 'Bureau of Economic Analysis',
            'where': "SERIESCODE = 'A191RX'",
            'unpivot': false,
            'measure_name': "'GDP (Real)'",
            'measure_value': 'B.DATAVALUE / 3',
            'granularity_id': 'TABLENAME, LINEDESCRIPTION)',
            'join': "LEFT JOIN {{ ref('dim_date_monthly') }} D ON LEFT(B.TIMEPERIOD, 4) = D.YEAR AND RIGHT(B.TIMEPERIOD, 2) = D.QUARTER_NAME"
        },
        {
            'id': 10,
            'name': 'bea_gdp_region',
            'dataset': 'GDP',
            'datasource': 'Bureau of Economic Analysis',
            'unpivot': false,
            'measures': 'GDP by County',
            'granularity_id': 'GEONAME',
            'join': "LEFT JOIN {{ ref('dim_date_monthly') }} D ON B.TIMEPERIOD = D.YEAR"
        },
        {
            'id': 11,
            'name': 'adp_employment',
            'dataset': 'EMPLOYEMENT',
            'datasource': 'ADP',
            'measures': 'ner, ner_sa',
            'where': "TIMESTEP = 'M'",
            'unpivot': true,
            'granularity_id': 'agg_ris, category'
        },
        {
            'id': 12,
            'name': 'adp_payinsights',
            'dataset': 'PAYINSIGHTS',
            'datasource': 'ADP',
            'measures': 'median_pay_change, median_annual_pay',
            'where': "TIMESTEP = 'M'",
            'unpivot': true,
            'granularity_id': 'category'
        },
        {
            'id': 13,
            'name': 'weather_daily_obs',
            'dataset': 'WEATHER_DAILY_OBS',
            'datasource': 'WEATHER',
            'measures': 'TEMP_MAX_DAY_F, TEMP_MIN_DAY_F, TEMP_AVG_DAY_F, TEMP_MAX_24H_F, TEMP_MIN_24H_F, PRECIP_TOTAL_IN, PRECIP_DAY_IN, SNOW_TOTAL_IN, SNOW_DAY_IN, CLOUD_AVG_24H_PCT, CLOUD_AVG_DAY_PCT, WIND_AVG_24H_MPH, WIND_AVG_DAY_MPH, HUMIDITY_AVG_24H_PCT, HUMIDITY_AVG_DAY_PCT',
            'unpivot': true,
            'granularity_id': 'CITY, STATE',
        }
    ] %}
    {{ return(datasets) }}
{% endmacro %}