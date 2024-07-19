import psycopg2
from psycopg2 import sql

from database.db_constants import DB_CONFIG

# Establish a connection to the database
conn = psycopg2.connect(**DB_CONFIG)

# Create a cursor object
cur = conn.cursor()

# Create SeaConditions table
cur.execute("""
    CREATE TABLE SeaConditions (
        ConditionID SERIAL PRIMARY KEY,
        Date DATE,
        TimeOfDay VARCHAR(50),
        LocationID INT,
        WaveHeight DECIMAL,
        WindWaveHeight DECIMAL,
        SwellWaveHeight DECIMAL,
        WaveDirection DECIMAL,
        WindWaveDirection DECIMAL,
        SwellWaveDirection DECIMAL,
        WavePeriod DECIMAL,
        WindWavePeriod DECIMAL,
        SwellWavePeriod DECIMAL,
        WindWavePeakPeriod DECIMAL,
        SwellWavePeakPeriod DECIMAL,
        WindSpeed DECIMAL,
        WindDirection VARCHAR(50),
        Weather VARCHAR(100),
        CreatedAt TIMESTAMP,
        DeletedAt TIMESTAMP
    )
""")

cur.execute("""
    CREATE TABLE PredictedSeaConditions (
        ConditionID SERIAL PRIMARY KEY,
        Date DATE,
        TimeOfDay VARCHAR(50),
        LocationID INT,
        WaveHeight DECIMAL,
        WindWaveHeight DECIMAL,
        SwellWaveHeight DECIMAL,
        WaveDirection DECIMAL,
        WindWaveDirection DECIMAL,
        SwellWaveDirection DECIMAL,
        WavePeriod DECIMAL,
        WindWavePeriod DECIMAL,
        SwellWavePeriod DECIMAL,
        WindWavePeakPeriod DECIMAL,
        SwellWavePeakPeriod DECIMAL,
        WindSpeed DECIMAL,
        WindDirection VARCHAR(50),
        Weather VARCHAR(100),
        CreatedAt TIMESTAMP,
        DeletedAt TIMESTAMP
        CONSTRAINT unique_date_location UNIQUE (Date, TimeOfDay, LocationID)
    )
""")

# Create ComputedSeaConditions table
cur.execute("""
    CREATE TABLE ComputedSeaConditions (
        ConditionID SERIAL PRIMARY KEY,
        TimeOfDay VARCHAR(50),
        LocationID INT,
        SurfDifficulty VARCHAR(50),
        WaveQuality VARCHAR(50),
        WindImpact DECIMAL,
        Recommendation VARCHAR(255),
        ComputationTime TIMESTAMP,
        CreatedAt TIMESTAMP,
        DeletedAt TIMESTAMP
    )
""")

# # Create Locations table
cur.execute("""
    CREATE TABLE Locations (
        LocationID SERIAL PRIMARY KEY,
        LocationName VARCHAR(100),
        Coordinates JSONB,
        CreatedAt TIMESTAMP,
        DeletedAt TIMESTAMP
    )
""")

# Add foreign key constraint to SeaConditions table
cur.execute("""
    ALTER TABLE SeaConditions
    ADD CONSTRAINT fk_location
    FOREIGN KEY (LocationID)
    REFERENCES Locations(LocationID)
""")

cur.execute("""
    ALTER TABLE PredictedSeaConditions
    ADD CONSTRAINT fk_location
    FOREIGN KEY (LocationID)
    REFERENCES Locations(LocationID)
""")

# Add foreign key constraint to ComputedSeaConditions table
cur.execute("""
    ALTER TABLE ComputedSeaConditions
    ADD CONSTRAINT fk_condition
    FOREIGN KEY (LocationID)
    REFERENCES Locations(LocationID)
""")

# Commit the transaction
conn.commit()

# Close the connection
conn.close()
