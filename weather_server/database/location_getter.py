from flask import Flask, jsonify
import psycopg2
import json
from database.db_constants import DB_CONFIG

app = Flask(__name__)

#need to put it server with link
@app.route('/getLocations', methods=['GET'])
def get_locations():
    # Connect to your PostgreSQL database
    conn = psycopg2.connect(**DB_CONFIG)
    cur = conn.cursor()

    # Query all locations
    cur.execute("SELECT * FROM Locations")
    rows = cur.fetchall()

    locations = []
    for row in rows:
        loc_dict = dict((cur.description[i][0], value) for i, value in enumerate(row))
        # Check if coordinates are complete
        if loc_dict['coordinates']['latitude'] is not None and loc_dict['coordinates']['longitude'] is not None:
            # Decode the location name
            locationname = json.loads('"' + loc_dict['locationname'] + '"')
            # Structure the output
            location = {
                'locationid': loc_dict['locationid'],
                'locationname': locationname,
                'coordinates': loc_dict['coordinates'],
                'createdat': loc_dict['createdat'],
                'deletedat': loc_dict['deletedat']
            }
            locations.append(location)

    # Close the connection
    cur.close()
    conn.close()

    return jsonify(locations)

if __name__ == '__main__':
    app.run()
