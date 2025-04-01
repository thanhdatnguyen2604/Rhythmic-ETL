# Million Song Dataset

This document provides information about the Million Song Dataset used in the Rhythmic-ETL project.

## Dataset Overview

The Million Song Dataset is a freely-available collection of audio features and metadata for a million contemporary popular music tracks. The dataset was created by The Echo Nest and is hosted by Columbia University.

### Key Features

- Contains metadata and audio features for 1,000,000 songs
- Includes artist information, release year, and audio features
- Available in HDF5 format
- Organized by artist name and song ID

## Dataset Structure

### Directory Organization

```
MillionSongSubset/
├── A/
│   ├── A/
│   │   ├── A/
│   │   │   └── TRAAAAW128F429D538.h5
│   │   └── B/
│   │       └── TRAAABD128F92C8A3A.h5
│   └── B/
│       └── C/
│           └── TRAAACD128F92C8A3A.h5
└── B/
    └── C/
        └── D/
            └── TRAAADD128F92C8A3A.h5
```

### File Format

Each song is stored in an HDF5 file with the following structure:

```python
{
    'metadata': {
        'songs': {
            'artist_name': str,
            'release': str,
            'title': str,
            'year': int,
            'artist_id': str,
            'song_id': str
        }
    },
    'analysis': {
        'songs': {
            'tempo': float,
            'energy': float,
            'loudness': float,
            'danceability': float,
            'hotttnesss': float
        }
    },
    'musicbrainz': {
        'songs': {
            'artist_mbtags': str,
            'artist_mbtags_count': int
        }
    }
}
```

## Data Fields

### Metadata Fields

- `artist_name`: Name of the artist
- `release`: Album or single name
- `title`: Song title
- `year`: Release year
- `artist_id`: Unique identifier for the artist
- `song_id`: Unique identifier for the song

### Analysis Fields

- `tempo`: Beats per minute
- `energy`: Energy level (0-1)
- `loudness`: Overall loudness in dB
- `danceability`: Danceability score (0-1)
- `hotttnesss`: Popularity score (0-1)

### MusicBrainz Fields

- `artist_mbtags`: MusicBrainz tags for the artist
- `artist_mbtags_count`: Number of tags

## Usage in Rhythmic-ETL

### Data Preparation

1. Download the dataset:
   ```bash
   wget http://labrosa.ee.columbia.edu/~dpwe/tmp/millionsongsubset.tar.gz
   tar -xzf millionsongsubset.tar.gz
   ```

2. Configure Eventsim:
   ```json
   {
     "h5_data_path": "/data/MillionSongSubset",
     "num_songs": 1000,
     "num_users": 100,
     "events_per_second": 10
   }
   ```

### Data Processing

1. Eventsim reads HDF5 files and generates events:
   - Listen events
   - Page view events
   - Authentication events

2. Events are sent to Kafka topics:
   - `listen_events`
   - `page_view_events`
   - `auth_events`

3. Flink processes the events and stores them in GCS

## Data Quality

### Validation

- Check file integrity:
  ```bash
  find MillionSongSubset -name "*.h5" -type f -exec h5ls {} \;
  ```

- Verify metadata:
  ```python
  import h5py
  with h5py.File('path/to/song.h5', 'r') as f:
      print(f['metadata']['songs'][0])
  ```

### Cleaning

- Remove corrupted files
- Handle missing values
- Normalize audio features

## Performance Considerations

### Storage

- Dataset size: ~280GB uncompressed
- Compressed size: ~10GB
- Required disk space: ~300GB

### Processing

- Use parallel processing for HDF5 files
- Implement caching for frequently accessed data
- Optimize memory usage when reading files

## References

- [Million Song Dataset Website](http://millionsongdataset.com/)
- [Echo Nest API Documentation](http://developer.echonest.com/docs/v4)
- [HDF5 Documentation](https://www.hdfgroup.org/solutions/hdf5/)