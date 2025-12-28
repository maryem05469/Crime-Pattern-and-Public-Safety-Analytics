import pandas as pd
import os

# ==============================
# Paths
# ==============================
INPUT_CSV = "chicago_crimes_clean.csv"
OUTPUT_DIR = "star_schema_output"

os.makedirs(OUTPUT_DIR, exist_ok=True)

# ==============================
# Load dataset
# ==============================
df = pd.read_csv(INPUT_CSV)

# ==============================
# DIM DATE
# ==============================
dim_date = (
    df[[
        "Date",
        "Incident Year",
        "Incident Month",
        "Incident Day",
        "Incident Hour",
        "Incident Weekday",
        "Day Type",
        "Season"
    ]]
    .drop_duplicates()
    .sort_values("Date")
    .reset_index(drop=True)
)

dim_date.insert(0, "date_id", dim_date.index + 1)

# ==============================
# DIM LOCATION
# ==============================
dim_location = (
    df[[
        "District",
        "Ward",
        "Community Area",
        "Beat",
        "Location Description"
    ]]
    .drop_duplicates()
    .sort_values(["District", "Ward", "Community Area", "Beat"])
    .reset_index(drop=True)
)

dim_location.insert(0, "location_id", dim_location.index + 1)

# ==============================
# DIM INCIDENT
# ==============================
dim_incident = (
    df[[
        "Primary Type",
        "Description"
    ]]
    .drop_duplicates()
    .sort_values(["Primary Type", "Description"])
    .reset_index(drop=True)
)

dim_incident.insert(0, "incident_id", dim_incident.index + 1)

# ==============================
# FACT TABLE
# ==============================
fact_crime = df[[
    "ID",
    "Date",
    "District",
    "Ward",
    "Community Area",
    "Beat",
    "Location Description",
    "Primary Type",
    "Description",
    "Arrest",
    "Domestic",
    "Updated On",
    "Update Lag Days"
]].copy()

# ==============================
# JOIN DIM KEYS INTO FACT
# ==============================
fact_crime = fact_crime.merge(
    dim_date[["date_id", "Date"]],
    on="Date",
    how="left"
)

fact_crime = fact_crime.merge(
    dim_location,
    on=["District", "Ward", "Community Area", "Beat", "Location Description"],
    how="left"
)

fact_crime = fact_crime.merge(
    dim_incident,
    on=["Primary Type", "Description"],
    how="left"
)

# ==============================
# FINAL FACT TABLE COLUMNS
# ==============================
fact_crime = fact_crime[[
    "ID",
    "date_id",
    "location_id",
    "incident_id",
    "Arrest",
    "Domestic",
    "Updated On",
    "Update Lag Days"
]]

# ==============================
# SAVE FILES
# ==============================
dim_date.to_csv(f"{OUTPUT_DIR}/dim_date.csv", index=False)
dim_location.to_csv(f"{OUTPUT_DIR}/dim_location.csv", index=False)
dim_incident.to_csv(f"{OUTPUT_DIR}/dim_incident.csv", index=False)
fact_crime.to_csv(f"{OUTPUT_DIR}/fact_crime.csv", index=False)

print("✅ Star schema created successfully")
print("📁 Output folder:", OUTPUT_DIR)