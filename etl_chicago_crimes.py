from pathlib import Path
import pandas as pd
import numpy as np

RAW_CSV_PATH = "chicago_crimes_raw.csv"
OUT_DIR = Path("output_week2")
OUT_DIR.mkdir(exist_ok=True)
CLEAN_CSV_PATH = OUT_DIR / "chicago_crimes_clean.csv"
TMP_FIXED_CSV = OUT_DIR / "tmp_fixed.csv"

COLUMNS_TO_REMOVE = [
    "Case Number", "Block", "IUCR", "FBI Code",
    "X Coordinate", "Y Coordinate", "Latitude", "Longitude", "Location"
]

def detect_encoding(path: str) -> str:
    with open(path, "rb") as f:
        b = f.read(4)
    if b.startswith(b"\xef\xbb\xbf"):
        return "utf-8-sig"
    if b.startswith(b"\xff\xfe") or b.startswith(b"\xfe\xff"):
        return "utf-16"
    return "utf-8-sig"

def unwrap_excel_quoted_csv(in_path: str, out_path: str, enc: str) -> None:
    """
    Fix files where each line is one big quoted string like:
    "ID,""Case Number"",""Date"",..."
    -> remove outer quotes and unescape doubled quotes.
    """
    with open(in_path, "r", encoding=enc, errors="replace", newline="") as fin, \
         open(out_path, "w", encoding="utf-8", newline="") as fout:
        for line in fin:
            line = line.rstrip("\n\r")
            
            if len(line) >= 2 and line[0] == '"' and line[-1] == '"':
                line = line[1:-1]
                
                line = line.replace('""', '"')
            fout.write(line + "\n")


enc = detect_encoding(RAW_CSV_PATH)
try:
    df = pd.read_csv(RAW_CSV_PATH, sep=",", quotechar='"', encoding=enc)
except UnicodeDecodeError:
    df = pd.read_csv(RAW_CSV_PATH, sep=",", quotechar='"', encoding="latin1")

if len(df.columns) <= 5:
    unwrap_excel_quoted_csv(RAW_CSV_PATH, TMP_FIXED_CSV, enc)
    df = pd.read_csv(TMP_FIXED_CSV, sep=",", quotechar='"', encoding="utf-8")


if len(df.columns) <= 5:
    raise ValueError(f"Still parsed into {len(df.columns)} columns. The CSV is malformed.")

df.columns = [c.strip() for c in df.columns]
print("✅ Columns parsed:", len(df.columns))


df = df.drop(columns=[c for c in COLUMNS_TO_REMOVE if c in df.columns], errors="ignore")


df = df.drop_duplicates()

for col in ["Date", "Updated On"]:
    if col in df.columns:
        df[col] = pd.to_datetime(df[col], errors="coerce")

df = df.dropna(subset=["Date", "Primary Type"])

for col in ["Primary Type", "Description", "Location Description"]:
    if col in df.columns:
        df[col] = df[col].astype(str).str.strip()
        df.loc[df[col].isin(["nan", "None", ""]), col] = np.nan
        df[col] = df[col].fillna("Unknown")

for col in ["Arrest", "Domestic"]:
    if col in df.columns:
        s = df[col].astype(str).str.lower().str.strip()
        df[col] = s.map({
            "true": "Yes", "false": "No",
            "1": "Yes", "0": "No",
            "y": "Yes", "n": "No"
        }).fillna("Unknown")

for col in ["District", "Ward", "Community Area", "Beat"]:
    if col in df.columns:
        df[col] = pd.to_numeric(df[col], errors="coerce")


df["Incident Year"] = df["Date"].dt.year
df["Incident Month"] = df["Date"].dt.month
df["Incident Day"] = df["Date"].dt.day
df["Incident Hour"] = df["Date"].dt.hour
df["Incident Weekday"] = df["Date"].dt.day_name()
df["Day Type"] = np.where(df["Date"].dt.weekday >= 5, "Weekend", "Weekday")

df["Season"] = np.select(
    [
        df["Incident Month"].isin([12, 1, 2]),
        df["Incident Month"].isin([3, 4, 5]),
        df["Incident Month"].isin([6, 7, 8]),
        df["Incident Month"].isin([9, 10, 11])
    ],
    ["Winter", "Spring", "Summer", "Fall"],
    default="Unknown"
)

if "Updated On" in df.columns:
    df["Update Lag Days"] = (
        (df["Updated On"] - df["Date"]).dt.total_seconds() / 86400
    ).round(2)

print("✅ Rows after cleaning:", len(df))


df.to_csv(CLEAN_CSV_PATH, index=False, encoding="utf-8")
print("🎯 Clean dataset saved to:", CLEAN_CSV_PATH)
print("✅ Week 2 ETL completed successfully")
