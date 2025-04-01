#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Rhythmic-ETL: Flink streaming job để xử lý các sự kiện từ Kafka và lưu vào Google Cloud Storage
"""

import os
import json
import logging
from datetime import datetime

from pyflink.datastream import StreamExecutionEnvironment
from pyflink.table import StreamTableEnvironment, EnvironmentSettings
from pyflink.table.descriptors import Schema, Kafka, Json, Rowtime

from streaming_functions import process_listen_events, process_page_view_events, process_auth_events
from schema import listen_event_schema, page_view_event_schema, auth_event_schema

# Cấu hình logging
logging.basicConfig(level=logging.INFO,
                   format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Lấy các biến môi trường
KAFKA_BOOTSTRAP_SERVERS = os.environ.get('KAFKA_BROKER', 'kafka-vm:9092')
GCS_BUCKET = os.environ.get('GCS_BUCKET', 'rhythmic-bucket')

def create_kafka_source(env, topic, schema, table_name):
    """Tạo Kafka source table cho Flink"""
    t_env = StreamTableEnvironment.create(env)
    
    t_env.connect(
        Kafka()
        .version("universal")
        .topic(topic)
        .start_from_latest()
        .property("bootstrap.servers", KAFKA_BOOTSTRAP_SERVERS)
        .property("group.id", "rhythmic-etl-{}".format(topic))
    ).with_format(
        Json()
        .fail_on_missing_field(False)
        .schema(schema)
    ).with_schema(
        Schema()
        .field("event_time", "TIMESTAMP(3)")
        .rowtime(
            Rowtime()
            .timestamps_from_field("ts")
            .watermarks_periodic_bounded(60000)
        )
        .fields_from_schema(schema)
    ).create_temporary_table(table_name)
    
    return t_env.from_path(table_name)

def main():
    """Hàm chính để chạy job Flink streaming"""
    logger.info("Bắt đầu Flink streaming job")
    
    # Tạo môi trường thực thi Flink
    env = StreamExecutionEnvironment.get_execution_environment()
    env.set_parallelism(1)  # Giới hạn parallelism cho e2-micro
    
    # Các topic Kafka cần xử lý
    kafka_topics = [
        {"name": "listen_events", "schema": listen_event_schema, "processor": process_listen_events},
        {"name": "page_view_events", "schema": page_view_event_schema, "processor": process_page_view_events},
        {"name": "auth_events", "schema": auth_event_schema, "processor": process_auth_events}
    ]
    
    try:
        # Xử lý cho từng loại sự kiện
        for topic_config in kafka_topics:
            topic = topic_config["name"]
            schema = topic_config["schema"]
            processor = topic_config["processor"]
            
            logger.info("Đang thiết lập xử lý cho topic {}".format(topic))
            
            # Tạo Kafka source
            source_table = create_kafka_source(env, topic, schema, "{}_source".format(topic))
            
            # Chuyển đổi Table sang DataStream
            stream = t_env.to_append_stream(
                source_table,
                'Row(event_time, *)'
            )
            
            # Xử lý sự kiện và lưu vào GCS
            stream.map(lambda row: processor(row, GCS_BUCKET))
            
        # Thực thi job
        env.execute("Rhythmic-ETL Streaming Job")
    except Exception as e:
        logger.error("Lỗi khi chạy Flink job: {}".format(str(e)))
        raise

if __name__ == "__main__":
    main() 