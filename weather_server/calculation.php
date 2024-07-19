<?php
try {
    putenv('TF_ENABLE_ONEDNN_OPTS=0');
    // Install the Python requirements
    shell_exec('pip install --upgrade pip');
    shell_exec('pip install -r requirements.txt');

    // Execute the Python script
    $calc_output = shell_exec('python quality_calculation.py');
    if ($calc_output === null) {
        throw new Exception("Failed to execute 'python weather_request.py'");
    }

    // Print the output of the Python script
    echo "Output: " . $calc_output;
} catch (Exception $e) {
    // Handle the exception
    echo "An error occurred: " . $e->getMessage();
}
?>
