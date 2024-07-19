#!/bin/bash

# Log file locations
STARTUP_LOG="/var/log/startup-script.log"
WEATHER_LOG="/var/log/weather_request.log"
PREDICTION_LOG="/var/log/prediction_calculation.log"
QUALITY_LOG="/var/log/quality_calculation.log"

# Ensure log directory exists
mkdir -p /var/log

# Function to log and execute a command
log_and_execute() {
    local COMMAND=$1
    echo "Executing: $COMMAND" | tee -a $STARTUP_LOG
    eval $COMMAND >> $STARTUP_LOG 2>&1
    local EXIT_CODE=$?
    if [[ $EXIT_CODE -ne 0 ]]; then
        echo "Error: Command failed with exit code $EXIT_CODE" | tee -a $STARTUP_LOG
        exit $EXIT_CODE
    fi
}

echo "Starting startup script..." | tee -a $STARTUP_LOG

# Update package list and install required packages
log_and_execute "apt-get update"
log_and_execute "apt-get install -y python3-pip python3-venv google-cloud-sdk"

# Create a virtual environment
log_and_execute "python3 -m venv env"
log_and_execute "source env/bin/activate"

# Download the requirements fixwle
log_and_execute "gsutil cp gs://weatherserver/requirements.txt ."

# Install Python package dependencies
log_and_execute "pip install -r requirements.txt"

# Download the Python scripts from Google Cloud Storage
log_and_execute "gsutil cp gs://weatherserver/weather_request.py ."
log_and_execute "gsutil cp gs://weatherserver/prediction_calculation.py ."
log_and_execute "gsutil cp gs://weatherserver/quality_calculation.py ."
log_and_execute "gsutil cp gs://weatherserver/database/db_constants.py ."
log_and_execute "gsutil cp gs://weatherserver/lstm_time_series_predictor.py ."

# Ensure the scripts are executable
chmod +x weather_request.py
chmod +x prediction_calculation.py
chmod +x quality_calculation.py

# Run the main Python scripts and log the output
log_and_execute "python3 weather_request.py"
WEATHER_EXIT_CODE=$?

log_and_execute "python3 prediction_calculation.py"
PREDICTION_EXIT_CODE=$?

log_and_execute "python3 quality_calculation.py"
QUALITY_EXIT_CODE=$?

# Check for errors in the scripts
if [[ $WEATHER_EXIT_CODE -ne 0 || $PREDICTION_EXIT_CODE -ne 0 || $QUALITY_EXIT_CODE -ne 0 ]]; then
    echo "Error detected in one of the Python scripts. Check logs for details." | tee -a $STARTUP_LOG
else
    echo "All scripts executed successfully." | tee -a $STARTUP_LOG
fi

# Shutdown the VM after the script completes
echo "Shutting down the VM" | tee -a $STARTUP_LOG
sudo shutdown -h now
