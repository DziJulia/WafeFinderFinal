<?php
// Due the servers im running in crone job only supoort php i need to bypass it for setting up crone job
// to run pyton script.
// Install the Python requirements
shell_exec('pip install -r requirements.txt');

// Execute the Python script
$output = shell_exec('python weather_request.py');

// Print the output of the Python script for validation if run succcesfully
echo "Output: " . $output;
?>
