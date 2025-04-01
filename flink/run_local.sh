#!/bin/bash

# Install dependencies if not installed
echo "Check and install dependencies..."
if ! command -v python3 &> /dev/null; then
    echo "Install Python 3..."
    sudo apt update
    sudo apt install -y python3 python3-pip
fi

if [ ! -f /usr/bin/python ]; then
    echo "Create symbolic link from python3 to python..."
    sudo ln -sf /usr/bin/python3 /usr/bin/python
fi

# Install Python libraries
echo "Install Python libraries..."
pip3 install --user apache-flink kafka-python google-cloud-storage

# Set environment variables
export PYFLINK_EXECUTABLE=python3
export PYTHONPATH=$PYTHONPATH:$(pwd)

# Run Flink job
echo "Run Flink job..."
cd jobs
flink run -py stream_all_events.py -pym stream_all_events

# Check job status
echo "Check job status..."
flink list 