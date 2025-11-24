import pandas as pd
import os
import numpy as np

# Base directory
base_dir = ""

# List of expected GTFS files with sample columns
gtfs_files = {
    'agency.csv': 'agency_id,agency_name',
    'stops.csv': 'stop_id,stop_name,stop_lat,stop_lon',
    'routes.csv': 'route_id,route_short_name,route_type',
    'trips.csv': 'route_id,trip_id,service_id',
    'stop_times.csv': 'trip_id,arrival_time,departure_time,stop_id',
    'calendar.csv': 'service_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,start_date,end_date',
    'calendar_dates.csv': 'service_id,date,exception_type'
}

for file_name, sample_columns in gtfs_files.items():
    full_path = os.path.join(base_dir, file_name) if base_dir else file_name
    if os.path.exists(full_path):
        try:
            df = pd.read_csv(full_path, encoding='latin-1')
            print(f"\nProcessing {file_name} ({len(df)} rows, columns: {list(df.columns)})")
            print(df.head())
            if file_name == 'agency.csv':
                df['agency_name'] = 'Kinatwa Sacco'
                df.to_csv(full_path, index=False, encoding='utf-8')
                print(f"Updated {file_name} with Kinatwa Sacco")
        except UnicodeDecodeError as e:
            print(f"Error decoding {file_name}: {e}. Trying to skip bad lines...")
            df = pd.read_csv(full_path, encoding='latin-1', on_bad_lines='skip')
            print(f"\nProcessing {file_name} with skipped lines ({len(df)} rows, columns: {list(df.columns)})")
            print(df.head())
            if file_name == 'agency.csv':
                df['agency_name'] = 'Kinatwa Sacco'
                df.to_csv(full_path, index=False, encoding='utf-8')
    else:
        print(f"Warning: {file_name} not found at {full_path}")

# Special handling for stops.csv
stops_path = os.path.join(base_dir, 'stops.csv') if base_dir else 'stops.csv'
if os.path.exists(stops_path):
    stops_df = pd.read_csv(stops_path, encoding='latin-1')
    print(f"\nOriginal stops.csv: {len(stops_df)} rows")
    
    # Filter to 500 stops (adjust as needed, e.g., 100-500)
    stops_df = stops_df.head(500)
    
    # Assign approximate Greenpark/Shamba coordinates with variation
    base_lat, base_lon = -1.29, 36.82  # Approximate center near Nairobi outskirts
    stops_df['stop_lat'] = base_lat + np.random.uniform(-0.01, 0.01, len(stops_df))  # ±0.01 degrees (~1 km)
    stops_df['stop_lon'] = base_lon + np.random.uniform(-0.01, 0.01, len(stops_df))
    
    # Optional: Add wheelchair_boarding if missing
    if 'wheelchair_boarding' not in stops_df.columns:
        stops_df['wheelchair_boarding'] = 0  # Default to 0, update manually if data exists
    
    print("\nFirst 5 stops with updated coordinates:")
    print(stops_df.head())
    stops_df.to_csv(stops_path, index=False, encoding='utf-8')
    print(f"Updated {stops_path} with 500 stops and new coordinates")

# ================== FIREBASE UPLOAD ==================
print("\nUploading data to Firebase...")

import firebase_admin
from firebase_admin import credentials, db
import os

# UPDATE THESE PATHS!
FIREBASE_KEY_PATH = r"C:\MoveEasy_project\moveeasy-478313-firebase-adminsdk-fbsvc-743d74e7b1.json"
DATABASE_URL = "https://moveeasy-478313-default-rtdb.firebaseio.com/"  # ← YOUR EXACT URL

if not os.path.exists(FIREBASE_KEY_PATH):
    print(f"ERROR: Key not found at {FIREBASE_KEY_PATH}")
else:
    cred = credentials.Certificate(FIREBASE_KEY_PATH)
    firebase_admin.initialize_app(cred, {'databaseURL': DATABASE_URL})

    # CLEAN & UPLOAD STOPS
    stops_df = pd.read_csv('stops.csv', encoding='utf-8').head(500)
    stops_df = stops_df.replace({float('nan'): None})  # ← Replace NaN with None
    stops_df = stops_df.dropna(subset=['stop_lat', 'stop_lon'])  # ← Remove rows with bad coords
    print(f"Cleaned stops: {len(stops_df)} rows (removed NaN)")

    db.reference('stops').set(stops_df.to_dict(orient='records'))
    print("Uploaded stops to Firebase")

    # UPLOAD ROUTES
    routes_df = pd.read_csv('routes.csv', encoding='utf-8').head(50)
    routes_df = routes_df.fillna('')  # Replace NaN in strings
    db.reference('routes').set(routes_df.to_dict(orient='records'))
    print("Uploaded routes to Firebase")

    print("Firebase upload complete!")
# ====================================================