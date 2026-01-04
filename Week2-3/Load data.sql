use chicago_crimes_dw;

LOAD DATA LOCAL INFILE 'D:/studies/BA IT/BI/star_schema_output/dim_date.csv'
INTO TABLE dim_date
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'D:/studies/BA IT/BI/star_schema_output/dim_location.csv'
INTO TABLE dim_location
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(@old_location_id, district, ward, community_area, beat, location_description);


LOAD DATA LOCAL INFILE 'D:/studies/BA IT/BI/star_schema_output/dim_incident.csv'
INTO TABLE dim_incident
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(@old_incident_id, primary_type, description);


LOAD DATA LOCAL INFILE 'D:/studies/BA IT/BI/star_schema_output/fact_crime.csv'
INTO TABLE fact_crime
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(id, date_id, location_id, incident_id,
 @Arrest, @Domestic, Updated_On, Update_Lag_Days)
SET
 Arrest   = IF(@Arrest = 'Yes', 1, 0),
 Domestic = IF(@Domestic = 'Yes', 1, 0);
