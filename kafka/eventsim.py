#!/usr/bin/env python3
import os
import json
import time
import random
import h5py
import pandas as pd
from datetime import datetime, timedelta
from kafka import KafkaProducer
import argparse
from tqdm import tqdm

def load_config(config_path):
    with open(config_path, 'r') as f:
        return json.load(f)

def get_song_data(h5_path):
    with h5py.File(h5_path, 'r') as f:
        return {
            'song_id': f['metadata']['songs']['song_id'][0].decode('utf-8'),
            'title': f['metadata']['songs']['title'][0].decode('utf-8'),
            'artist_name': f['metadata']['songs']['artist_name'][0].decode('utf-8'),
            'year': f['metadata']['songs']['year'][0],
            'duration': f['metadata']['songs']['duration'][0]
        }

def create_producer(broker):
    return KafkaProducer(
        bootstrap_servers=broker,
        value_serializer=lambda v: json.dumps(v).encode('utf-8')
    )

def generate_listen_event(user_id, song_data):
    return {
        'user_id': user_id,
        'song_id': song_data['song_id'],
        'title': song_data['title'],
        'artist_name': song_data['artist_name'],
        'timestamp': datetime.now().isoformat()
    }

def generate_page_view_event(user_id):
    return {
        'user_id': user_id,
        'page': random.choice(['home', 'search', 'artist', 'album']),
        'timestamp': datetime.now().isoformat()
    }

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--config', required=True, help='Path to config file')
    args = parser.parse_args()

    config = load_config(args.config)
    producer = create_producer(config['kafka_broker'])

    # Get list of h5 files
    h5_files = []
    for root, _, files in os.walk(config['h5_data_path']):
        for file in files:
            if file.endswith('.h5'):
                h5_files.append(os.path.join(root, file))

    start_time = datetime.fromisoformat(config['from_time'])
    duration = timedelta(hours=int(config['duration'].replace('h', '')))
    end_time = start_time + duration

    current_time = start_time
    while current_time < end_time:
        for user_id in range(config['nusers']):
            # Generate listen events
            if random.random() < 0.7:  # 70% chance of listen event
                song_data = get_song_data(random.choice(h5_files))
                event = generate_listen_event(user_id, song_data)
                producer.send('listen_events', event)

            # Generate page view events
            if random.random() < 0.3:  # 30% chance of page view
                event = generate_page_view_event(user_id)
                producer.send('page_view_events', event)

            time.sleep(random.uniform(0.1, 1.0))  # Random delay between events

        current_time += timedelta(minutes=1)
        time.sleep(1)  # Wait 1 second before next minute

    producer.close()

if __name__ == '__main__':
    main() 