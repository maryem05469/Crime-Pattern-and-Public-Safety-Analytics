CREATE DATABASE IF NOT EXISTS chicago_crimes_dw;
USE chicago_crimes_dw;

CREATE TABLE dim_date (
    date_id INT PRIMARY KEY,
    date DATE NOT NULL,
    incident_year INT NOT NULL,
    incident_month INT NOT NULL,
    incident_day INT NOT NULL,
    incident_hour INT NOT NULL,
    incident_weekday VARCHAR(10) NOT NULL,
    day_type VARCHAR(10) NOT NULL,
    season VARCHAR(10) NOT NULL
);
CREATE TABLE dim_location (
    location_id INT PRIMARY KEY,
    district INT,
    ward DECIMAL(10,2),
    community_area DECIMAL(10,2),
    beat INT,
    location_description VARCHAR(100)
);
CREATE TABLE dim_incident (
    incident_id INT PRIMARY KEY,
    primary_type VARCHAR(50) NOT NULL,
    description VARCHAR(100)
);
CREATE TABLE fact_crime (
    id INT PRIMARY KEY,

    date_id INT NOT NULL,
    location_id INT NOT NULL,
    incident_id INT NOT NULL,

    Arrest BOOLEAN NOT NULL,
    Domestic BOOLEAN NOT NULL,

    Updated_On DATETIME NOT NULL,
    Update_Lag_Days INT NOT NULL,

    FOREIGN KEY (date_id) REFERENCES dim_date(date_id),
    FOREIGN KEY (location_id) REFERENCES dim_location(location_id),
    FOREIGN KEY (incident_id) REFERENCES dim_incident(incident_id)
);




