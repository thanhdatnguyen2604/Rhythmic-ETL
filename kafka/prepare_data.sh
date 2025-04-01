#!/bin/bash

# Script to prepare data directory structure for Kafka and Zookeeper
# This script creates necessary directories and downloads the Million Song Dataset

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting data preparation script...${NC}"

# Create base directories
echo -e "${YELLOW}Creating directory structure...${NC}"
mkdir -p data/zookeeper/log
mkdir -p data/kafka
mkdir -p config

# Set correct permissions
echo -e "${YELLOW}Setting permissions...${NC}"
chmod -R 777 data
chmod -R 777 config

# Create minimal configuration
echo -e "${YELLOW}Creating minimal configuration...${NC}"
cat > config/config.json << EOF
{
    "kafka_broker": "localhost:9092",
    "h5_data_path": "/data/MillionSongSubset",
    "topics": {
        "listen_events": {
            "name": "listen_events",
            "partitions": 1
        },
        "page_view_events": {
            "name": "page_view_events",
            "partitions": 1
        }
    }
}
EOF

# Download Million Song Dataset
echo -e "${YELLOW}Creating Million Song Dataset directory...${NC}"
mkdir -p data/MillionSongSubset

echo -e "${YELLOW}Checking available disk space...${NC}"
FREE_SPACE=$(df -h . | awk 'NR==2 {print $4}')
echo -e "Available space: ${GREEN}${FREE_SPACE}${NC}"
echo -e "${YELLOW}The Million Song Dataset requires at least 10GB of free space.${NC}"

echo -e "${YELLOW}Downloading Million Song Dataset (This will take a while)...${NC}"
wget -O data/msds.tar.gz http://static.echonest.com/millionsongsubset_full.tar.gz

# Check if download was successful
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to download Million Song Dataset!${NC}"
    echo -e "${YELLOW}Trying alternative source...${NC}"
    wget -O data/msds.tar.gz http://labrosa.ee.columbia.edu/~dpwe/tmp/millionsongsubset.tar.gz
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to download from alternative source as well.${NC}"
        echo -e "${RED}Please download the Million Song Dataset manually and extract it to data/MillionSongSubset${NC}"
        exit 1
    fi
fi

echo -e "${YELLOW}Extracting dataset (this may take several minutes)...${NC}"
tar -xzf data/msds.tar.gz -C data/

echo -e "${YELLOW}Cleaning up...${NC}"
rm data/msds.tar.gz

echo -e "${YELLOW}Verifying extraction...${NC}"
H5_COUNT=$(find data -name "*.h5" | wc -l)
echo -e "Found ${GREEN}${H5_COUNT}${NC} HDF5 files"

if [ "$H5_COUNT" -eq 0 ]; then
    echo -e "${RED}No HDF5 files found! Extraction may have failed.${NC}"
    echo -e "${RED}Please download and extract the Million Song Dataset manually.${NC}"
    exit 1
fi

echo -e "${GREEN}Million Song Dataset successfully downloaded and extracted.${NC}"
echo -e "${GREEN}Data preparation complete!${NC}"
echo -e "${GREEN}You can now start Kafka and Zookeeper using: docker-compose up -d${NC}" 