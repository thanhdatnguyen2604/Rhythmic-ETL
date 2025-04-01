#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Rhythmic-ETL: Streaming processing functions for Flink
"""

import os
import json
import logging
from datetime import datetime
from google.cloud import storage

# Configure logging
logging.basicConfig(level=logging.INFO,
                   format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Initialize GCS client
storage_client = storage.Client()

def save_to_gcs(data, bucket_name, object_name):
    """Save data to Google Cloud Storage"""
    try:
        bucket = storage_client.bucket(bucket_name)
        blob = bucket.blob(object_name)
        blob.upload_from_string(data)
        logger.info("Saved data to gs://{}/{}".format(bucket_name, object_name))
        return True
    except Exception as e:
        logger.error("Error saving to GCS: {}".format(str(e)))
        return False

def get_partition_path(event_time, event_type):
    """Create partition path by year/month/day/hour"""
    dt = datetime.fromtimestamp(event_time / 1000)  # Convert from milliseconds
    return "{}/year={}/month={:02d}/day={:02d}/hour={:02d}".format(event_type, dt.year, dt.month, dt.day, dt.hour)

def process_listen_events(row, bucket_name):
    """Process listen events and save to GCS"""
    try:
        # Convert Row to dict
        event = row._asdict()
        event_time = event.get('ts', datetime.now().timestamp() * 1000)
        
        # Prepare data to save
        processed_data = {
            'listen_id': event.get('listen_id'),
            'user_id': event.get('user_id'),
            'song_id': event.get('song_id'),
            'artist': event.get('artist'),
            'song': event.get('song'),
            'duration': event.get('duration'),
            'ts': event.get('ts'),
            'datetime': datetime.fromtimestamp(event_time / 1000).isoformat()
        }
        
        # Create partition path and object name
        partition_path = get_partition_path(event_time, 'listen_events')
        object_name = "{}/{}".format(partition_path, event.get('listen_id'))
        object_name = "{}.json".format(object_name)
        
        # Save to GCS
        save_to_gcs(json.dumps(processed_data), bucket_name, object_name)
        
        return processed_data
    except Exception as e:
        logger.error("Error processing listen_event: {}".format(str(e)))
        return None

def process_page_view_events(row, bucket_name):
    """Process page view events and save to GCS"""
    try:
        # Convert Row to dict
        event = row._asdict()
        event_time = event.get('ts', datetime.now().timestamp() * 1000)
        
        # Prepare data to save
        processed_data = {
            'page_view_id': event.get('page_view_id'),
            'user_id': event.get('user_id'),
            'page': event.get('page'),
            'section': event.get('section'),
            'referrer': event.get('referrer'),
            'browser': event.get('browser'),
            'os': event.get('os'),
            'device': event.get('device'),
            'ts': event.get('ts'),
            'datetime': datetime.fromtimestamp(event_time / 1000).isoformat()
        }
        
        # Create partition path and object name
        partition_path = get_partition_path(event_time, 'page_view_events')
        object_name = "{}/{}".format(partition_path, event.get('page_view_id'))
        object_name = "{}.json".format(object_name)
        
        # Save to GCS
        save_to_gcs(json.dumps(processed_data), bucket_name, object_name)
        
        return processed_data
    except Exception as e:
        logger.error("Error processing page_view_event: {}".format(str(e)))
        return None

def process_auth_events(row, bucket_name):
    """Process auth events and save to GCS"""
    try:
        # Convert Row to dict
        event = row._asdict()
        event_time = event.get('ts', datetime.now().timestamp() * 1000)
        
        # Prepare data to save
        processed_data = {
            'auth_id': event.get('auth_id'),
            'user_id': event.get('user_id'),
            'level': event.get('level'),
            'method': event.get('method'),
            'status': event.get('status'),
            'ts': event.get('ts'),
            'datetime': datetime.fromtimestamp(event_time / 1000).isoformat()
        }
        
        # Create partition path and object name
        partition_path = get_partition_path(event_time, 'auth_events')
        object_name = "{}/{}".format(partition_path, event.get('auth_id'))
        object_name = "{}.json".format(object_name)
        
        # Save to GCS
        save_to_gcs(json.dumps(processed_data), bucket_name, object_name)
        
        return processed_data
    except Exception as e:
        logger.error("Error processing auth_event: {}".format(str(e)))
        return None 