<?php
//http://wavefinderapp.fun/getLocations.php
// Connect to PostgreSQL database
$host = "postgresql.r6.websupport.sk";
$port = "5432";
$dbname = "wavefinderapp";
$user = "wavefinderapp";
$password = "Bl7Vqw4/)0";

try {
    $dsn = "pgsql:host=$host;port=$port;dbname=$dbname;user=$user;password=$password";
    $pdo = new PDO($dsn);
} catch (PDOException $e) {
    die("Connection failed: " . $e->getMessage());
}

// Query all locations
$sql = "SELECT * FROM Locations";
$stmt = $pdo->query($sql);

$locations = [];
while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
    // Decode the coordinates JSON string
    $coordinates = json_decode($row['coordinates'], true);

    // Check if coordinates are complete
    if ($coordinates['latitude'] !== null && $coordinates['longitude'] !== null) {
        // Round latitude and longitude to 6 decimal places
        $latitude = round($coordinates['latitude'], 6);
        $longitude = round($coordinates['longitude'], 6);

        // Structure the output
        $location = [
            'locationid' => $row['locationid'],
            'locationname' => $row['locationname'],
            'coordinates' => ['latitude' => $latitude, 'longitude' => $longitude],
            'createdat' => $row['createdat'],
            'deletedat' => $row['deletedat']
        ];
        $locations[] = $location;
    }
}

// Close the database connection
$pdo = null;

// Output JSON response
header('Content-Type: application/json');
echo json_encode($locations);
?>
