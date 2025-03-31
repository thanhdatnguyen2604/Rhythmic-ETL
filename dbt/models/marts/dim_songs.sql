with listen_events as (
    select * from {{ ref('stg_listen_events') }}
),

song_stats as (
    select
        song_id,
        artist,
        song,
        count(*) as listen_count,
        avg(duration) as avg_duration
    from listen_events
    group by 1, 2, 3
)

select
    song_id,
    artist,
    song,
    listen_count,
    avg_duration
from song_stats
