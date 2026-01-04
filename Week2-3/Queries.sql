use chicago_crimes_dw;

/*1. Core Volume Measures*/
/*Total Incident Count*/
SELECT COUNT(f.id) AS total_incidents
FROM fact_crime f;

/*Incidents per District*/
SELECT l.district,
       COUNT(f.id) AS incident_count
FROM fact_crime f
JOIN dim_location l ON f.location_id = l.location_id
GROUP BY l.district
ORDER BY incident_count DESC;

/*Incidents per Community Area*/
SELECT l.community_area,
       COUNT(f.id) AS incident_count
FROM fact_crime f
JOIN dim_location l ON f.location_id = l.location_id
GROUP BY l.community_area
ORDER BY incident_count DESC;

/*2. Temporal Measures*/
/*Monthly Incident Count*/
SELECT d.incident_month,
       COUNT(f.id) AS monthly_incidents
FROM fact_crime f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.incident_month
ORDER BY d.incident_month;

/*Monthly Incident Trend (%)*/
WITH monthly_counts AS (
    SELECT d.incident_month,
           COUNT(f.id) AS incident_count
    FROM fact_crime f
    JOIN dim_date d ON f.date_id = d.date_id
    GROUP BY d.incident_month
)
SELECT incident_month,
       incident_count,
       ROUND(
           (incident_count -
            LAG(incident_count) OVER (ORDER BY incident_month))
           / LAG(incident_count) OVER (ORDER BY incident_month)
           * 100, 2
       ) AS monthly_trend_percent
FROM monthly_counts;

/*Monthly Incident Count*/
SELECT d.incident_hour,
       COUNT(f.id) AS incident_count
FROM fact_crime f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.incident_hour
ORDER BY incident_count DESC;
/* LIMIT 1; for peak hour*/

/*Incident Seasonality Index*/
SELECT d.season,
       COUNT(f.id) AS incident_count
FROM fact_crime f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.season
ORDER BY incident_count DESC;

/*Incident Count by Primary Type*/
SELECT i.primary_type,
       COUNT(f.id) AS incident_count
FROM fact_crime f
JOIN dim_incident i ON f.incident_id = i.incident_id
GROUP BY i.primary_type
ORDER BY incident_count DESC;

/*Location-Type Distribution (%)*/
SELECT l.location_description,
       COUNT(f.id) AS incident_count,
       ROUND(
           COUNT(f.id) * 100.0 /
           (SELECT COUNT(*) FROM fact_crime), 2
       ) AS percentage
FROM fact_crime f
JOIN dim_location l ON f.location_id = l.location_id
GROUP BY l.location_description
ORDER BY percentage DESC;

/*Incidents by Day Type*/
SELECT d.day_type,
       COUNT(f.id) AS incident_count
FROM fact_crime f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.day_type;

/*Daytime vs Nighttime Incidents*/
SELECT
    CASE
        WHEN d.incident_hour BETWEEN 6 AND 17 THEN 'Daytime'
        ELSE 'Nighttime'
    END AS time_of_day,
    COUNT(f.id) AS incident_count
FROM fact_crime f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY time_of_day;

/*Arrest Rate (%)*/
SELECT
    ROUND(
        SUM(CASE WHEN Arrest = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(id),
        2
    ) AS arrest_rate_percent
FROM fact_crime;

/*Arrest Rate by District*/
SELECT l.district,
       ROUND(
           SUM(CASE WHEN f.Arrest = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(f.id),
           2
       ) AS arrest_rate_percent
FROM fact_crime f
JOIN dim_location l ON f.location_id = l.location_id
GROUP BY l.district
ORDER BY arrest_rate_percent DESC;

/*Arrest Rate by Incident Type*/
SELECT i.primary_type,
       ROUND(
           SUM(CASE WHEN f.Arrest = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(f.id),
           2
       ) AS arrest_rate_percent
FROM fact_crime f
JOIN dim_incident i ON f.incident_id = i.incident_id
GROUP BY i.primary_type
ORDER BY arrest_rate_percent DESC;

/*Data Update Lag (Days)*/
SELECT
    ROUND(AVG(Update_Lag_Days), 2) AS avg_update_lag_days
FROM fact_crime;

/*Emerging Community Area Patterns*/
SELECT l.community_area,
       d.incident_month,
       COUNT(f.id) AS incident_count
FROM fact_crime f
JOIN dim_date d ON f.date_id = d.date_id
JOIN dim_location l ON f.location_id = l.location_id
GROUP BY l.community_area, d.incident_month
ORDER BY l.community_area, d.incident_month;
