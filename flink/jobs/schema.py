#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Rhythmic-ETL: Định nghĩa schema cho các sự kiện
"""

# Schema cho listen_events
listen_event_schema = {
    'listen_id': 'STRING',
    'user_id': 'STRING',
    'song_id': 'STRING',
    'artist': 'STRING', 
    'song': 'STRING',
    'duration': 'INT',
    'ts': 'BIGINT'
}

# Schema cho page_view_events
page_view_event_schema = {
    'page_view_id': 'STRING',
    'user_id': 'STRING',
    'page': 'STRING',
    'section': 'STRING',
    'referrer': 'STRING',
    'browser': 'STRING',
    'os': 'STRING',
    'device': 'STRING',
    'ts': 'BIGINT'
}

# Schema cho auth_events
auth_event_schema = {
    'auth_id': 'STRING',
    'user_id': 'STRING',
    'level': 'STRING',
    'method': 'STRING',
    'status': 'STRING',
    'ts': 'BIGINT'
} 