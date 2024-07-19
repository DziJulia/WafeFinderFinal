from datetime import datetime, timedelta
import psycopg2
import pandas as pd
from multiprocessing import Pool, cpu_count

from database.db_constants import DB_CONFIG

# Define functions for calculations
def calculate_surf_difficulty(row):
    """
    Calculate the difficulty of surfing based on wave height, wind speed, and swell wave height.

    @param row: A dictionary or similar data structure that includes 'waveheight', 'windspeed', and 'swellwaveheight'.

    @return: A string representing the difficulty of surfing ('High', 'Medium', 'Low').
    """
    if row['waveheight'] > 2 and row['windspeed'] > 5 and row['swellwaveheight'] > 2:
        return 'High'
    elif row['waveheight'] > 1 and row['windspeed'] > 3 and row['swellwaveheight'] > 1:
        return 'Medium'
    else:
        return 'Low'

def calculate_wave_quality(row):
    """
    Calculate the quality of waves based on wave height, wave period, swell wave period, and wind wave height.

    @param row: A dictionary or similar data structure that includes 'waveheight', 'waveperiod', 'swellwaveperiod', and 'windwaveheight'.

    @return: A string representing the quality of waves ('Excellent', 'Good', 'Fair', 'Poor').
    """
    if row['waveheight'] > 2 and row['waveperiod'] > 10 and row['swellwaveperiod'] > 10 and row['windwaveheight'] < 1.5:
        return 'Excellent'
    elif row['waveheight'] > 1 and row['waveperiod'] > 7 and row['swellwaveperiod'] > 7 and row['windwaveheight'] < 2:
        return 'Good'
    elif row['waveheight'] > 1 and row['waveperiod'] > 5 and row['swellwaveperiod'] > 5 and row['windwaveheight'] < 3:
        return 'Fair'
    else:
        return 'Poor'

def calculate_wind_impact(row):
    """
    The purpose of this function is to be adjusting the impact of wind based on certain thresholds.
    If the wind speed is high and the resulting wave height is significant, it likely indicates a stronger impact,
    hence the higher multiplier (0.8). If the conditions are not met, it suggests a lower impact, hence the lower multiplier (0.5).

    @param row: A dictionary or similar data structure that includes 'waveheight', 'waveperiod', 'swellwaveperiod', and 'windwaveheight'.

    @return: A integer
    """
    if row['windspeed'] > 5 and row['windwaveheight'] > 2:
        return float(row['windspeed']) * 0.8
    else:
        return float(row['windspeed']) * 0.5

def generate_recommendation(surfDifficulty, waveQuality):
    recommendations = []
    for surf_difficulty, wave_quality in zip(surfDifficulty, waveQuality):
        if surf_difficulty == 'Low' and wave_quality in ['Excellent', 'Good']:
            recommendations.append('Great conditions for all surfers')
        elif surf_difficulty != 'Low' and wave_quality in ['Excellent', 'Good']:
            recommendations.append('Good conditions for experienced surfers')
        else:
            recommendations.append('Not recommended for surfing')
    return recommendations

def process_location(location_id):
    # Establish a connection to the database inside the process
    conn = psycopg2.connect(**DB_CONFIG)
    cur = conn.cursor()
    
    start_date = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
    end_date = start_date + timedelta(days=3)
    print("Processing Location ID:", location_id)
    current_date = start_date
    while current_date < end_date:
        cur.execute("""
            SELECT * FROM PredictedSeaConditions
            WHERE "date" = %s AND "locationid" = %s
            ORDER BY "timeofday" ASC
        """, (current_date.date(), location_id))
        rows = cur.fetchall()
        df = pd.DataFrame(rows, columns=[desc[0] for desc in cur.description])
        
        surfDifficulty = df.apply(calculate_surf_difficulty, axis=1)
        waveQuality = df.apply(calculate_wave_quality, axis=1)
        windImpact = df.apply(calculate_wind_impact, axis=1)
        recommendation = generate_recommendation(surfDifficulty, waveQuality)
        
        for index, row in df.iterrows():
            cur.execute("""
                INSERT INTO ComputedSeaConditions (LocationID, TimeofDay, SurfDifficulty, WaveQuality, WindImpact, Recommendation, CreatedAt)
                VALUES (%s, %s, %s, %s, %s, %s, NOW())
               ON CONFLICT ON CONSTRAINT computedseaconditions_locationid_timeofday
                DO UPDATE SET
                    LocationID = EXCLUDED.LocationID,
                    TimeofDay = EXCLUDED.TimeofDay,
                    SurfDifficulty = EXCLUDED.SurfDifficulty,
                    WaveQuality = EXCLUDED.WaveQuality,
                    WindImpact = EXCLUDED.WindImpact,
                    Recommendation = EXCLUDED.Recommendation,
                    CreatedAt = NOW()
            """, (location_id, current_date, surfDifficulty[index], waveQuality[index], windImpact[index], recommendation[index]))
            conn.commit()
        
        current_date += timedelta(hours=1)
    print('Finished Location', location_id)
    cur.close()
    conn.close()

if __name__ == "__main__":
    # Establish a connection outside the processes
    conn_master = psycopg2.connect(**DB_CONFIG)
    cur_master = conn_master.cursor()
    
    # Fetch location IDs
    cur_master.execute("SELECT locationid FROM Locations")
    location_data = cur_master.fetchall()
    location_ids = [row[0] for row in location_data]
    cur_master.close()
    conn_master.close()
    
    
    # Process each location in parallel
    with Pool(cpu_count()) as pool:
        pool.map(process_location, location_ids)