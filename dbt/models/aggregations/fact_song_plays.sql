{{ config(materialized='table') }}

WITH song_plays AS (
    SELECT 
        {{ dbt_utils.surrogate_key(['sessionid', 'itemInSession']) }} AS play_id,
        userId AS user_id,
        {{ dbt_utils.surrogate_key(['artist', 'song']) }} AS song_id,
        ts AS timestamp,
        sessionid AS session_id,
        artist,
        song,
        duration
    FROM {{ ref('stg_listen_events') }}
)

SELECT *
FROM song_plays 