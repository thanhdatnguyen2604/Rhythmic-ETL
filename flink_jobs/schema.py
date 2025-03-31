#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Rhythmic-ETL: Định nghĩa schema cho các loại sự kiện
"""

from pyflink.table import DataTypes

# Schema cho sự kiện nghe nhạc
listen_event_schema = DataTypes.ROW([
    DataTypes.FIELD("listen_id", DataTypes.STRING()),
    DataTypes.FIELD("user_id", DataTypes.STRING()),
    DataTypes.FIELD("song_id", DataTypes.STRING()),
    DataTypes.FIELD("artist", DataTypes.STRING()),
    DataTypes.FIELD("song", DataTypes.STRING()),
    DataTypes.FIELD("duration", DataTypes.DOUBLE()),
    DataTypes.FIELD("ts", DataTypes.BIGINT())
])

# Schema cho sự kiện xem trang
page_view_event_schema = DataTypes.ROW([
    DataTypes.FIELD("page_view_id", DataTypes.STRING()),
    DataTypes.FIELD("user_id", DataTypes.STRING()),
    DataTypes.FIELD("page", DataTypes.STRING()),
    DataTypes.FIELD("section", DataTypes.STRING()),
    DataTypes.FIELD("referrer", DataTypes.STRING()),
    DataTypes.FIELD("browser", DataTypes.STRING()),
    DataTypes.FIELD("os", DataTypes.STRING()),
    DataTypes.FIELD("device", DataTypes.STRING()),
    DataTypes.FIELD("ts", DataTypes.BIGINT())
])

# Schema cho sự kiện xác thực
auth_event_schema = DataTypes.ROW([
    DataTypes.FIELD("auth_id", DataTypes.STRING()),
    DataTypes.FIELD("user_id", DataTypes.STRING()),
    DataTypes.FIELD("level", DataTypes.STRING()),
    DataTypes.FIELD("method", DataTypes.STRING()),
    DataTypes.FIELD("status", DataTypes.STRING()),
    DataTypes.FIELD("ts", DataTypes.BIGINT())
]) 