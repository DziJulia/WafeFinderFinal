import psycopg2
import requests
from psycopg2 import sql
import json

from database.db_constants import API_BEACH, DB_CONFIG

"""
  This script will be run only once for creating and putting beach name and lat and long to the database which
  be stored for all users.
"""

conn = psycopg2.connect(**DB_CONFIG)
cur = conn.cursor()

def get_lat_long(address):
    """
    This function uses the Positionstack API to get the latitude and longitude of a given address.
    """
    base_url = "http://api.positionstack.com/v1/forward"
    params = {
        "access_key": API_BEACH,
        "query": address
    }
    response = requests.get(base_url, params=params)
    if response.status_code == 200:
        data = response.json()
        if data['data']:
            location = data['data'][0]
            return location['latitude'], location['longitude']
    return None, None

def get_beaches_in_ireland():
    """
      This function fetches the names of all the beaches in Ireland using the Overpass API.
      The Overpass API is a read-only API that serves up custom selected parts of the OSM map data.

      Returns:
          list: A list of beach names if the API request is successful. Returns an empty list otherwise.
    """
    overpass_url = "http://overpass-api.de/api/interpreter"
    overpass_query = """
      [out:json];
      area["ISO3166-1"="IE"]->.ireland;
      (
        node["natural"="beach"](area.ireland);
        way["natural"="beach"](area.ireland);
        relation["natural"="beach"](area.ireland);
      );
      out;
    """

    response = requests.get(overpass_url, params={'data': overpass_query})

    if response.status_code == 200:
        data = response.json()
        beaches_with_names = [element['tags']['name'] for element in data['elements'] if 'tags' in element and 'name' in element['tags']]
        return beaches_with_names
    else:
        print("Error fetching data:", response.text)
        return []

if __name__ == "__main__":
    cur = conn.cursor()
    """
      This is the main entry point of the program. It calls the function get_beaches_in_ireland() to
      fetch the names of all the beaches in Ireland.
      It then prints the number of beaches found and their names.
    """
    beaches = get_beaches_in_ireland()
    print("Number of beaches found:", len(beaches))
    # Insert each beach into the Locations table
    for beach in beaches:
        lat, lng = get_lat_long(beach)
        coordinates = json.dumps({'latitude': lat, 'longitude': lng})
        # print(beach)
        # print(coordinates)
        cur.execute(
            sql.SQL("""
                INSERT INTO Locations (LocationName, Coordinates, CreatedAt)
                VALUES (%s, %s, NOW())
            """),
            (beach, coordinates)
        )

    # Commit the transaction
    conn.commit()

    # Close the connection
    conn.close()
