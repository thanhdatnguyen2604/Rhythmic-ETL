#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Rhythmic-ETL: Flink streaming job to process events from Kafka and save to Google Cloud Storage
"""

import os
import json
import logging
import sys
from datetime import datetime

from pyflink.datastream import StreamExecutionEnvironment, CheckpointingMode, CheckpointConfig
from pyflink.table import StreamTableEnvironment, EnvironmentSettings
from pyflink.common import RestartStrategies, Time

from streaming_functions import process_listen_events, process_page_view_events, process_auth_events
from schema import listen_event_schema, page_view_event_schema, auth_event_schema

# Configure logging
logging.basicConfig(level=logging.INFO,
                   format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Get environment variables
KAFKA_BOOTSTRAP_SERVERS = os.environ.get('KAFKA_BROKER', 'kafka-vm:9092')
GCS_BUCKET = os.environ.get('GCS_BUCKET', 'rhythmic-bucket')
CHECKPOINT_DIR = os.environ.get('CHECKPOINT_DIR', 'file:///opt/flink/checkpoints')
CHECKPOINT_INTERVAL = int(os.environ.get('CHECKPOINT_INTERVAL', '60000'))  # 60 seconds
PARALLELISM = int(os.environ.get('PARALLELISM', '1'))

# Check Google Cloud credentials
GOOGLE_CREDENTIALS_PATH = os.environ.get('GOOGLE_APPLICATION_CREDENTIALS', '/opt/flink/secrets/cred.json')
if not os.path.exists(GOOGLE_CREDENTIALS_PATH):
    logger.error("GOOGLE_APPLICATION_CREDENTIALS does not exist: {}".format(GOOGLE_CREDENTIALS_PATH))
    logger.error("Please set the credentials file at /opt/flink/secrets/cred.json or set the environment variable")
    logger.info("Will continue running but may not save data to GCS")

def create_kafka_source(t_env, topic, schema_fields, table_name):
    """Create Kafka source table for Flink"""
    
    # Create CREATE TABLE SQL
    fields_sql = ", ".join(["{} {}".format(field, type) for field, type in schema_fields.items()])
    
    sql = """
    CREATE TABLE {table_name} (
        {fields_sql},
        event_time AS CAST(ts AS TIMESTAMP(3)),
        WATERMARK FOR event_time AS event_time - INTERVAL '5' SECOND
    ) WITH (
        'connector' = 'kafka',
        'topic' = '{topic}',
        'properties.bootstrap.servers' = '{servers}',
        'properties.group.id' = 'rhythmic-etl-{topic}',
        'scan.startup.mode' = 'latest-offset',
        'format' = 'json'
    )
    """.format(table_name=table_name, fields_sql=fields_sql, topic=topic, servers=KAFKA_BOOTSTRAP_SERVERS)
    
    # Execute SQL
    logger.info("Creating Kafka source table with SQL: {}".format(sql))
    t_env.execute_sql(sql)
    
    return t_env.from_path(table_name)

def configure_environment(env):
    """Configure Flink environment with checkpointing and performance parameters"""
    # Set parallelism
    env.set_parallelism(PARALLELISM)
    
    # Configure checkpointing
    env.enable_checkpointing(CHECKPOINT_INTERVAL, CheckpointingMode.EXACTLY_ONCE)
    checkpoint_config = env.get_checkpoint_config()
    checkpoint_config.set_checkpoint_storage_dir(CHECKPOINT_DIR)
    checkpoint_config.set_min_pause_between_checkpoints(5000)  # 5 seconds
    checkpoint_config.set_max_concurrent_checkpoints(1)
    checkpoint_config.set_checkpoint_timeout(30000)  # 30 seconds
    
    # Configure restart strategy when error occurs
    env.set_restart_strategy(RestartStrategies.fixed_delay_restart(
        3,  # maximum number of restarts
        Time.seconds(10)  # delay between restarts
    ))
    
    # Configure buffer timeout for network
    env.get_config().set_autowater_mark_interval(200)
    env.get_config().set_buffer_timeout(100)  # Buffer timeout (ms)
    
    # Allow late events
    env.get_config().set_latency_tracking_interval(5000)  # 5 seconds
    
    return env

def main():
    """Main function to run Flink streaming job"""
    logger.info("Starting Flink streaming job")
    logger.info("Kafka Bootstrap Servers: {}".format(KAFKA_BOOTSTRAP_SERVERS))
    logger.info("GCS Bucket: {}".format(GCS_BUCKET))
    logger.info("Checkpoint Directory: {}".format(CHECKPOINT_DIR))
    logger.info("Checkpoint Interval: {} ms".format(CHECKPOINT_INTERVAL))
    logger.info("Parallelism: {}".format(PARALLELISM))
    
    # Check Kafka connection
    try:
        from kafka.admin import KafkaAdminClient
        admin_client = KafkaAdminClient(bootstrap_servers=KAFKA_BOOTSTRAP_SERVERS)
        topics = admin_client.list_topics()
        logger.info("Kafka connection successful. Topics: {}".format(topics))
    except Exception as e:
        logger.warning("Cannot connect to Kafka: {}".format(str(e)))
        logger.warning("Will continue but may not receive data from Kafka")
    
    # Create Flink execution environment
    env = StreamExecutionEnvironment.get_execution_environment()
    
    # Configure environment with checkpointing and performance parameters
    env = configure_environment(env)
    
    # Create table environment
    t_env = StreamTableEnvironment.create(env)
    
    # Add Kafka connector jar
    t_env.get_config().get_configuration().set_string(
        "pipeline.jars", "file:///opt/flink/lib/flink-connector-kafka-1.17.0.jar;file:///opt/flink/lib/flink-json-1.17.0.jar"
    )
    
    # Kafka topics to process
    kafka_topics = [
        {"name": "listen_events", "schema": listen_event_schema, "processor": process_listen_events},
        {"name": "page_view_events", "schema": page_view_event_schema, "processor": process_page_view_events},
        {"name": "auth_events", "schema": auth_event_schema, "processor": process_auth_events}
    ]
    
    try:
        # Process each event type
        for topic_config in kafka_topics:
            topic = topic_config["name"]
            schema = topic_config["schema"]
            processor = topic_config["processor"]
            
            logger.info("Setting up processing for topic {}".format(topic))
            
            # Create Kafka source
            source_table = create_kafka_source(t_env, topic, schema, "{}_source".format(topic))
            
            # Convert Table to DataStream
            stream = t_env.to_data_stream(source_table)
            
            # Process events and save to GCS
            stream.map(lambda row: processor(row, GCS_BUCKET))
            
        # Execute job
        env.execute("Rhythmic-ETL Streaming Job")
    except Exception as e:
        logger.error("Error running Flink job: {}".format(str(e)))
        logger.exception(e)
        raise

if __name__ == "__main__":
    main() 