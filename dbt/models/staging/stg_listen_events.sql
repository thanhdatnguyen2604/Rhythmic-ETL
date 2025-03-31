{{ config(materialized='view') }}

with source as (
    select * from {{ source('rhythmic', 'ext_listen_events') }}
),

renamed as (
    select
        listen_id,
        user_id,
        song_id,
        artist,
        song,
        duration,
        ts,
        datetime
    from source
)

select * from renamed 