<?php
try {
    $start_time = microtime(true);

    putenv('TF_ENABLE_ONEDNN_OPTS=0');
    // Install the Python requirements
    shell_exec('pip install --upgrade pip');
    shell_exec('pip install -r requirements.txt');

    // Execute the second Python script
    $prediction_output = shell_exec('python prediction_calculation.py');
    if ($prediction_output === null) {
        throw new Exception("Failed to execute 'python prediction_calculation.py'");
    }

    // Print the output of the second Python script
    echo "Finished machine learning";
    
    $end_time = microtime(true);
    $execution_time = $end_time - $start_time;

    echo "Execution time of script = ".$execution_time." sec";
} catch (Exception $e) {
    // Handle the exception
    echo "An error occurred: " . $e->getMessage();
}
?>
