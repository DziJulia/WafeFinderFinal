import psycopg2
import datetime
import requests
import openmeteo_requests
import datetime
import requests_cache
from retry_requests import retry

from database.db_constants import API_WEATHER, DB_CONFIG

# Establish a connection to the database
conn = psycopg2.connect(**DB_CONFIG)

# Setup the Open-Meteo API client with cache and retry on error
cache_session = requests_cache.CachedSession('.cache', expire_after = 3600)
retry_session = retry(cache_session, retries = 5, backoff_factor = 0.2)
openmeteo = openmeteo_requests.Client(session = retry_session)

def get_weather_history(latitude,longitude):
    #THis have to run every daypeobably at midnight
    #api_key = os.environ.get("WEATHER_API_KEY")

    # Calculate start date (yesterday)
    start_date = datetime.datetime.now() - datetime.timedelta(days=1)
    start_date_str = start_date.strftime("%Y-%m-%d")
    # Construct the URL query
    url = f"https://api.weatherapi.com/v1/history.json?key={API_WEATHER}&q={latitude},{longitude}&dt={start_date_str}&hourly=1"
    try:
        # Make GET request to the URL
        response = requests.get(url)
        # Check if request was successful (status code 200)
        if response.status_code == 200:
            # Parse JSON response
            data = response.json()
             # Extract only the desired fields
            extracted_data = []
            for day_data in data['forecast']['forecastday']:
                for hour_data in day_data['hour']:
                    extracted_data.append({
                        'temp_c': hour_data['temp_c'],
                        'wind_kph': hour_data['wind_kph'],
                        'wind_dir': hour_data['wind_dir'],
                        'icon': hour_data['condition']['icon'],
                        'time': hour_data['time']
                    })
                    
            return extracted_data
        else:
            print(f"Error: Failed to fetch weather data. Status code: {response.status_code}")
            return None
    except Exception as e:
        print(f"Error: {e}")
        return None

def get_first_location(cur):
    """
    This function fetches the first location and its ID from the Locations table in the database.
    """
    cur.execute("SELECT LocationID, LocationName, Coordinates FROM Locations ORDER BY LocationID ASC LIMIT 1")
    row = cur.fetchone()
    if row is not None:
        location_id, location_name, coordinates = row
        return location_id, location_name, coordinates['latitude'], coordinates['longitude']
    return None, None, None, None

def insert_marine_weather(cur, location_id, date, marine_weather_data):
    # Convert all values in the dictionary to float
    #marine_weather_data = {k: float(v) for k, v in marine_weather_data.items()}
    cur.execute("""
        INSERT INTO SeaConditions (
            Date, TimeOfDay, LocationID, WaveHeight, WindWaveHeight, SwellWaveHeight,
            WaveDirection, WindWaveDirection, SwellWaveDirection, WavePeriod,
            WindWavePeriod, SwellWavePeriod, WindWavePeakPeriod, SwellWavePeakPeriod,
            WindSpeed, WindDirection, Weather, CreatedAt, Icon
        ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
    """, (
        date, marine_weather_data['time_of_day'], location_id,
        float(marine_weather_data['wave_height']), float(marine_weather_data['wind_wave_height']), float(marine_weather_data['swell_wave_height']),
        float(marine_weather_data['wave_direction']), float(marine_weather_data['wind_wave_direction']), float(marine_weather_data['swell_wave_direction']),
        float(marine_weather_data['wave_period']), float(marine_weather_data['wind_wave_period']), float(marine_weather_data['swell_wave_period']),
        float(marine_weather_data['wind_wave_peak_period']), float(marine_weather_data['swell_wave_peak_period']), float(marine_weather_data['wind_speed']),
        marine_weather_data['wind_direction'], marine_weather_data['temp_c'],  datetime.datetime.now(), marine_weather_data['icon']
    ))

def is_specific_date_data_present(cur, location_id, date):
    """
    Check if data for a specific date is already present in the database for a given location.
    """
    cur.execute("""
        SELECT COUNT(*)
        FROM SeaConditions
        WHERE Date = %s AND LocationID = %s
    """, (date, location_id))
    count = cur.fetchone()[0]
    return count > 0

def get_all_locations(cur):
    """
    This function fetches all locations from the Locations table in the database.
    """
    cur.execute("SELECT LocationID, LocationName, Coordinates FROM Locations")
    rows = cur.fetchall()
    locations = []
    for row in rows:
        location_id, location_name, coordinates = row
        locations.append((location_id, location_name, coordinates['latitude'], coordinates['longitude']))
    return locations

def get_marine_weather(latitude, longitude):
    # Make sure all required weather variables are listed here
    # The order of variables in hourly or daily is important to assign them correctly below
    start_date = datetime.datetime.now() - datetime.timedelta(days=1)
    start_date_str = start_date.strftime("%Y-%m-%d")

    url = "https://marine-api.open-meteo.com/v1/marine"
    params = {
        "latitude": latitude,
        "longitude": longitude,
        "hourly": [
            "wave_height",
            "wave_direction",
            "wave_period",
            "wind_wave_height",
            "wind_wave_direction",
            "wind_wave_period",
            "wind_wave_peak_period",
            "swell_wave_height",
            "swell_wave_direction",
            "swell_wave_period",
            "swell_wave_peak_period"
        ],
        "start_date": start_date_str,
	    "end_date": start_date_str
    }
    responses = openmeteo.weather_api(url, params=params)
    return responses[0]

try:
    cur = conn.cursor()
    locations = get_all_locations(cur)
    for location in locations:
        location_id, location_name, latitude, longitude = location
        start_date = datetime.datetime.now() - datetime.timedelta(days=1)
        start_date_str = start_date.strftime("%Y-%m-%d")

        print("Location:", location_name, start_date_str)
        try:
            if latitude is not None and longitude is not None:
                if not is_specific_date_data_present(cur, location_id, start_date_str):
                    full_weather = get_marine_weather(latitude, longitude).Hourly()
                    history_weather = get_weather_history(latitude, longitude)
                    timestamp = datetime.datetime.fromtimestamp(full_weather.Time())
                    # Get the marine weather data for the past 7 days
                    for i in range(0, len(full_weather.Variables(0).ValuesAsNumpy())): 
                        date_format = "%Y-%m-%d %H:%M"
                        date_object = datetime.datetime.strptime(history_weather[i]['time'], date_format)
                        date =  date_object.date()
                        marine_weather_data = {
                            'time_of_day': history_weather[i]['time'],
                            'wind_speed': history_weather[i]['wind_kph'] if history_weather[i] and i < len(history_weather) else None,
                            'wind_direction': history_weather[i]['wind_dir'] if history_weather[i] and i < len(history_weather) else None,
                            'temp_c': history_weather[i]['temp_c'] if history_weather[i] and i < len(history_weather) else None,
                            'icon' : history_weather[i]['icon'] if history_weather[i] and i < len(history_weather) else None,
                            'wave_height': full_weather.Variables(0).ValuesAsNumpy()[i],
                            'wave_direction': full_weather.Variables(1).ValuesAsNumpy()[i],
                            'wave_period': full_weather.Variables(2).ValuesAsNumpy()[i],
                            'wind_wave_height': full_weather.Variables(3).ValuesAsNumpy()[i],
                            'wind_wave_direction': full_weather.Variables(4).ValuesAsNumpy()[i],
                            'wind_wave_period': full_weather.Variables(5).ValuesAsNumpy()[i],
                            'wind_wave_peak_period': full_weather.Variables(6).ValuesAsNumpy()[i],
                            'swell_wave_height': full_weather.Variables(7).ValuesAsNumpy()[i],
                            'swell_wave_direction': full_weather.Variables(8).ValuesAsNumpy()[i],
                            'swell_wave_period': full_weather.Variables(9).ValuesAsNumpy()[i],
                            'swell_wave_peak_period': full_weather.Variables(10).ValuesAsNumpy()[i],
                        }
                        insert_marine_weather(cur, location_id, date, marine_weather_data)
                else:
                    print("Yesterday's data already present in the database.")
            else:
                print("Latitude or longitude is None. Unable to retrieve coordinates for the specified place.")
        except Exception as e:
            print(f"An error occurred for location {location_name}: {e}")
except Exception as e:
    print("An error occurred:", e)
finally:
    conn.commit()
    cur.close()
    conn.close()