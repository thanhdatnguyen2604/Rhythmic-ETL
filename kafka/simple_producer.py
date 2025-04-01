#!/usr/bin/env python3
"""
Simple Kafka Producer using Million Song Dataset
Reads HDF5 files and generates music listening and page view events
"""

import json
import random
import time
import uuid
import os
import glob
from datetime import datetime
from kafka import KafkaProducer
import h5py

# Configuration
KAFKA_BROKER = os.environ.get("KAFKA_BROKER", "localhost:9092")
TOPICS = {
    "listen_events": "listen_events",
    "page_view_events": "page_view_events",
    "auth_events": "auth_events"
}
USERS = int(os.environ.get("USERS", "100"))
PAGES = ["home", "search", "artist", "song", "playlist", "profile"]
AUTH_STATUSES = ["success", "fail"]
AUTH_LEVELS = ["free", "premium", "family"]
INTERVAL_SEC = float(os.environ.get("INTERVAL_SEC", "0.5"))  # Send event every 0.5 seconds
H5_DATA_PATH = os.environ.get("H5_DATA_PATH", "/data/MillionSongSubset")
USE_RANDOM_DATA = os.environ.get("USE_RANDOM_DATA", "false").lower() == "true"

def create_producer():
    """Create and return a Kafka producer"""
    return KafkaProducer(
        bootstrap_servers=KAFKA_BROKER,
        value_serializer=lambda x: json.dumps(x).encode('utf-8')
    )

def load_song_files():
    """Load HDF5 files and return list of paths"""
    print(f"Looking for .h5 files in {H5_DATA_PATH}")
    song_files = []
    
    # Find all .h5 files recursively
    for root, dirs, files in os.walk(H5_DATA_PATH):
        for file in files:
            if file.endswith(".h5"):
                song_files.append(os.path.join(root, file))
    
    print(f"Found {len(song_files)} .h5 files")
    return song_files

def extract_song_data(h5_file):
    """Extract relevant data from an HDF5 file"""
    try:
        with h5py.File(h5_file, 'r') as f:
            # Debug - print structure of HDF5 file
            # print(f"HDF5 file structure for {h5_file}:")
            # print_hdf5_structure(f, "")
            
            # Different schema possibilities in Million Song Dataset
            if 'analysis' in f and 'songs' in f['analysis']:
                # Schema 1
                songs = f['analysis']['songs']
                if 'song_id' in songs:
                    song_id = songs['song_id'][0].decode('utf-8')
                    artist_id = songs['artist_id'][0].decode('utf-8')
                    title = songs['title'][0].decode('utf-8')
                    artist_name = songs['artist_name'][0].decode('utf-8')
                    duration = float(songs['duration'][0])
                    tempo = float(songs['tempo'][0])
                else:
                    raise KeyError("Song ID not found in analysis/songs")
            elif 'metadata' in f and 'songs' in f['metadata']:
                # Schema 2
                songs = f['metadata']['songs']
                song_id = songs[0]['song_id'][0].decode('utf-8')
                artist_id = songs[0]['artist_id'][0].decode('utf-8')
                title = songs[0]['title'][0].decode('utf-8')
                artist_name = songs[0]['artist_name'][0].decode('utf-8')
                duration = float(songs[0]['duration'][0])
                tempo = 120.0  # Default tempo if not available
            else:
                # Try looking at root level
                if 'song_id' in f:
                    song_id = f['song_id'][0].decode('utf-8')
                    artist_id = f['artist_id'][0].decode('utf-8')
                    title = f['title'][0].decode('utf-8')
                    artist_name = f['artist_name'][0].decode('utf-8')
                    duration = float(f['duration'][0]) if 'duration' in f else 240.0
                    tempo = float(f['tempo'][0]) if 'tempo' in f else 120.0
                else:
                    raise KeyError("Could not find song data in recognized schema")
            
            return {
                'song_id': song_id,
                'artist_id': artist_id,
                'title': title,
                'artist_name': artist_name,
                'duration': duration,
                'tempo': tempo
            }
    except Exception as e:
        # print(f"Error reading {h5_file}: {e}")
        return None

def print_hdf5_structure(obj, indent):
    """Helper function to print HDF5 structure"""
    for key in obj.keys():
        print(f"{indent}{key}")
        if isinstance(obj[key], h5py.Group):
            print_hdf5_structure(obj[key], indent + "  ")
        else:
            print(f"{indent}  {obj[key].shape} {obj[key].dtype}")

def generate_random_song_data():
    """Generate random song data when HDF5 files are not available"""
    song_id = f"S{random.randint(10000, 99999)}"
    artist_id = f"A{random.randint(10000, 99999)}"
    artists = ["The Beatles", "Queen", "Taylor Swift", "BTS", "Drake", "Beyoncé", 
               "Ed Sheeran", "Adele", "Bruno Mars", "Ariana Grande"]
    song_titles = ["Imagine", "Bohemian Rhapsody", "Shape of You", "Dynamite", 
                  "One Dance", "Halo", "Perfect", "Hello", "Uptown Funk", "7 Rings"]
    
    return {
        'song_id': song_id,
        'artist_id': artist_id,
        'title': random.choice(song_titles),
        'artist_name': random.choice(artists),
        'duration': random.uniform(180.0, 300.0),
        'tempo': random.uniform(80.0, 160.0)
    }

def generate_listen_event(song_data):
    """Generate a song listen event using real song data"""
    user_id = random.randint(1, USERS)
    event_time = datetime.now().isoformat()
    
    return {
        "event_id": str(uuid.uuid4()),
        "user_id": user_id,
        "song_id": song_data['song_id'],
        "artist_id": song_data['artist_id'],
        "title": song_data['title'],
        "artist_name": song_data['artist_name'],
        "duration_ms": int(song_data['duration'] * 1000),
        "tempo": song_data['tempo'],
        "event_time": event_time,
        "session_id": f"session_{user_id}_{int(time.time())}",
        "auth_token": f"token_{user_id}_{int(time.time())}",
        "user_agent": "Mozilla/5.0 (compatible; SimpleProducer/1.0)"
    }

def generate_page_view_event(song_data=None):
    """Generate a random page view event, optionally related to a song"""
    user_id = random.randint(1, USERS)
    event_time = datetime.now().isoformat()
    page = random.choice(PAGES)
    
    event = {
        "event_id": str(uuid.uuid4()),
        "user_id": user_id,
        "page": page,
        "event_time": event_time,
        "session_id": f"session_{user_id}_{int(time.time())}",
        "auth_token": f"token_{user_id}_{int(time.time())}",
        "user_agent": "Mozilla/5.0 (compatible; SimpleProducer/1.0)",
        "referrer": "direct"
    }
    
    # Add song context if page is song or artist and song_data is available
    if song_data and page in ["song", "artist"]:
        if page == "song":
            event["context_song_id"] = song_data["song_id"]
            event["context_title"] = song_data["title"]
        else:  # artist page
            event["context_artist_id"] = song_data["artist_id"]
            event["context_artist_name"] = song_data["artist_name"]
    
    return event

def generate_auth_event():
    """Generate a random authentication event"""
    user_id = random.randint(1, USERS)
    event_time = datetime.now().isoformat()
    status = random.choice(AUTH_STATUSES)
    
    event = {
        "event_id": str(uuid.uuid4()),
        "user_id": user_id,
        "event_time": event_time,
        "auth_status": status,
        "ip_address": f"192.168.{random.randint(1, 254)}.{random.randint(1, 254)}",
        "device": random.choice(["mobile", "desktop", "tablet"]),
        "session_id": f"session_{user_id}_{int(time.time())}",
        "user_agent": "Mozilla/5.0 (compatible; SimpleProducer/1.0)"
    }
    
    # Add more details if auth successful
    if status == "success":
        event["auth_level"] = random.choice(AUTH_LEVELS)
        event["auth_token"] = f"token_{user_id}_{int(time.time())}"
        event["login_method"] = random.choice(["email", "google", "facebook", "apple"])
    else:
        event["failure_reason"] = random.choice(["invalid_credentials", "account_locked", "expired_subscription"])
    
    return event

def main():
    """Main function to run the producer"""
    try:
        songs_data = []
        
        # Try to load song data from HDF5 files unless USE_RANDOM_DATA is set
        if not USE_RANDOM_DATA:
            # Load song files
            song_files = load_song_files()
            if song_files:
                # Pre-extract some song data to reduce file I/O
                print("Pre-extracting song data from some files...")
                sample_size = min(100, len(song_files))
                for file in random.sample(song_files, sample_size):
                    song_data = extract_song_data(file)
                    if song_data:
                        songs_data.append(song_data)
                
                print(f"Pre-extracted data for {len(songs_data)} songs")
            else:
                print(f"No .h5 files found in {H5_DATA_PATH}.")
                print("Will use random song data instead.")
        
        # If no songs extracted or USE_RANDOM_DATA is true, generate random data
        if not songs_data:
            print("Generating random song data...")
            for _ in range(100):
                songs_data.append(generate_random_song_data())
            print(f"Generated {len(songs_data)} random songs")
        
        # Create Kafka producer
        producer = create_producer()
        print(f"Connected to Kafka at {KAFKA_BROKER}")
        print(f"Sending events to topics: {list(TOPICS.values())}")
        print(f"Simulating {USERS} users")
        print(f"Interval between events: {INTERVAL_SEC} seconds")
        print(f"Press Ctrl+C to stop")
        
        counter = 0
        while True:
            # Get a random song
            song_data = random.choice(songs_data)
            
            # Generate and send a listen event (40% probability)
            if counter % 5 < 2:
                listen_event = generate_listen_event(song_data)
                producer.send(TOPICS["listen_events"], value=listen_event)
                print(f"Sent listen event: {listen_event['event_id']} - {song_data['title']} by {song_data['artist_name']}")
            
            # Generate and send a page view event (40% probability)
            if counter % 5 >= 2 and counter % 5 < 4:
                page_view_event = generate_page_view_event(song_data)
                producer.send(TOPICS["page_view_events"], value=page_view_event)
                print(f"Sent page view event: {page_view_event['event_id']} - Page: {page_view_event['page']}")
            
            # Generate and send an auth event (20% probability)
            if counter % 5 == 4:
                auth_event = generate_auth_event()
                producer.send(TOPICS["auth_events"], value=auth_event)
                print(f"Sent auth event: {auth_event['event_id']} - Status: {auth_event['auth_status']}")
            
            counter += 1
            time.sleep(INTERVAL_SEC)
            
    except KeyboardInterrupt:
        print("Stopping producer")
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
    finally:
        if 'producer' in locals():
            producer.close()

if __name__ == "__main__":
    main() 