from datetime import datetime, timedelta
import pandas as pd
import psycopg2
from keras import optimizers, backend as K
from lstm_time_series_predictor import LSTMTimeSeriesPredictor
from multiprocessing import Pool, cpu_count
import time

def get_nearest_direction(angle, angle_to_direction):
    return min(angle_to_direction.keys(), key=lambda x: abs(x - angle))

def create_connection():
    return psycopg2.connect(
        "host=postgresql.r6.websupport.sk "
        "port=5432 "
        "dbname=wavefinderapp "
        "user=wavefinderapp "
        "password=Bl7Vqw4/)0",

    )

def train_model(location_id):
    # Define the direction_to_angle dictionary
    direction_to_angle = {
        'N': 0, 'NNE': 22.5, 'NE': 45, 'ENE': 67.5,
        'E': 90, 'ESE': 112.5, 'SE': 135, 'SSE': 157.5,
        'S': 180, 'SSW': 202.5, 'SW': 225, 'WSW': 247.5,
        'W': 270, 'WNW': 292.5, 'NW': 315, 'NNW': 337.5
    }

    target_columns = [
        'WaveHeight', 'WindWaveHeight', 'SwellWaveHeight', 'WaveDirection',
        'WindWaveDirection', 'SwellWaveDirection', 'WavePeriod',
        'WindWavePeriod', 'SwellWavePeriod', 'WindWavePeakPeriod',
        'SwellWavePeakPeriod', 'WindSpeed', 'WindDirection', 'Weather'
    ]

    optimizer = optimizers.Adam(learning_rate=0.001)
    look_back = 16
    epochs = 100
    batch_size = 16
    dropout_rate = 0.2
    neurons = 64

    try:
        # First connection to retrieve data
        conn = create_connection()
        cur = conn.cursor()
        cur.execute("SELECT * FROM SeaConditions WHERE locationid = %s", (location_id,))
        data = cur.fetchall()
        colnames = [desc[0] for desc in cur.description]
        df_location = pd.DataFrame(data, columns=colnames)

        target_columns = [column.lower() for column in target_columns]
        df_location['winddirection'] = df_location['winddirection'].map(direction_to_angle)

        print('Location id ', location_id)

        regression = LSTMTimeSeriesPredictor(
            optimizer=optimizer, look_back=look_back, epochs=epochs,
            batch_size=batch_size, dropout_rate=dropout_rate, neurons=neurons
        )

        predictions = regression.train_and_predict(df_location, target_columns=target_columns, steps=72)

        results = {col: [prediction.item() for prediction in predictions[col]] for col in target_columns}

        print(f"Predictions for location {location_id} completed")

        date_now = datetime.now()
        now = date_now.replace(hour=1, minute=0, second=0, microsecond=0)
        angle_to_direction = {v: k for k, v in direction_to_angle.items()}

        # Close the initial connection after data retrieval and prediction
        cur.close()
        conn.close()

        # Re-establish the connection before inserting predictions
        conn = create_connection()
        cur = conn.cursor()

        for i in range(72):
            future_time = now + timedelta(hours=i)
            wind_dir_str = angle_to_direction[get_nearest_direction(round(results['winddirection'][i]) % 360, angle_to_direction)]

            cur.execute("""
                INSERT INTO PredictedSeaConditions (
                    Date, Timeofday, LocationID, WaveHeight, WindWaveHeight,
                    SwellWaveHeight, WaveDirection, WindWaveDirection,
                    SwellWaveDirection, CreatedAt, WindSpeed, Weather,
                    WavePeriod, WindWavePeriod, SwellWavePeriod, WindDirection
                )
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, NOW(), %s, %s, %s, %s, %s, %s)
                ON CONFLICT ON CONSTRAINT unique_date_time_location DO UPDATE
                SET Timeofday = excluded.Timeofday,
                    WaveHeight = excluded.WaveHeight,
                    WindWaveHeight = excluded.WindWaveHeight,
                    SwellWaveHeight = excluded.SwellWaveHeight,
                    WaveDirection = excluded.WaveDirection,
                    WindWaveDirection = excluded.WindWaveDirection,
                    SwellWaveDirection = excluded.SwellWaveDirection,
                    CreatedAt = excluded.CreatedAt,
                    WindSpeed = excluded.WindSpeed,
                    Weather = excluded.Weather,
                    WavePeriod = excluded.WavePeriod,
                    WindWavePeriod = excluded.WindWavePeriod,
                    SwellWavePeriod = excluded.SwellWavePeriod,
                    WindDirection = excluded.WindDirection
            """, (
                future_time.date(), future_time.time(), location_id,
                results['waveheight'][i], results['windwaveheight'][i],
                results['swellwaveheight'][i], results['wavedirection'][i],
                results['windwavedirection'][i], results['swellwavedirection'][i],
                results['windspeed'][i], results['weather'][i],
                results['waveperiod'][i], results['windwaveperiod'][i],
                results['swellwaveperiod'][i], wind_dir_str
            ))
        conn.commit()
    except Exception as e:
        print(f"An error occurred: {e}")
    finally:
        cur.close()
        conn.close()
        K.clear_session()  # Clear the session to prevent memory leaks

def fetch_location_ids():
    try:
        conn = create_connection()
        cur = conn.cursor()
        cur.execute("SELECT locationid FROM Locations WHERE locationid BETWEEN 375 AND 385")
        location_data = cur.fetchall()
        location_ids = [row[0] for row in location_data]
    finally:
        cur.close()
        conn.close()

    return location_ids

def train_models(location_ids):
    for location_id in location_ids:
        train_model(location_id)

if __name__ == '__main__':
    location_ids = fetch_location_ids()
    cpu = cpu_count()
    num_processes = min(len(location_ids), 8)  # Use the available CPU cores
    
    location_sets = [location_ids[i::num_processes] for i in range(num_processes)]

    with Pool(num_processes) as p:
        p.map(train_models, location_sets)
