from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.google.cloud.operators.bigquery import BigQueryCreateExternalTableOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2023, 1, 1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

GCP_PROJECT_ID = '{{ var.value.gcp_project_id }}'
GCS_BUCKET = '{{ var.value.gcs_bucket }}'
BIGQUERY_DATASET = '{{ var.value.bigquery_dataset }}'

dag = DAG(
    'gcs_to_bigquery',
    default_args=default_args,
    description='Create external tables from GCS to BigQuery',
    schedule_interval='@hourly',
    catchup=False,
    max_active_runs=1
)

# Create external table for listen_events
create_listen_events_table = BigQueryCreateExternalTableOperator(
    task_id='create_listen_events_table',
    table_resource={
        'tableReference': {
            'projectId': GCP_PROJECT_ID,
            'datasetId': BIGQUERY_DATASET,
            'tableId': 'ext_listen_events',
        },
        'externalDataConfiguration': {
            'sourceFormat': 'NEWLINE_DELIMITED_JSON',
            'sourceUris': [f'gs://{GCS_BUCKET}/listen_events/*.json'],
            'schema': {
                'fields': [
                    {'name': 'listen_id', 'type': 'STRING'},
                    {'name': 'user_id', 'type': 'STRING'},
                    {'name': 'song_id', 'type': 'STRING'},
                    {'name': 'artist', 'type': 'STRING'},
                    {'name': 'song', 'type': 'STRING'},
                    {'name': 'duration', 'type': 'FLOAT'},
                    {'name': 'ts', 'type': 'INTEGER'},
                    {'name': 'datetime', 'type': 'TIMESTAMP'}
                ]
            },
            'hivePartitioningOptions': {
                'mode': 'AUTO',
                'sourceUriPrefix': f'gs://{GCS_BUCKET}/listen_events/',
            }
        }
    },
    dag=dag
)

# Create external table for page_view_events
create_page_view_events_table = BigQueryCreateExternalTableOperator(
    task_id='create_page_view_events_table',
    table_resource={
        'tableReference': {
            'projectId': GCP_PROJECT_ID,
            'datasetId': BIGQUERY_DATASET,
            'tableId': 'ext_page_view_events',
        },
        'externalDataConfiguration': {
            'sourceFormat': 'NEWLINE_DELIMITED_JSON',
            'sourceUris': [f'gs://{GCS_BUCKET}/page_view_events/*.json'],
            'schema': {
                'fields': [
                    {'name': 'page_view_id', 'type': 'STRING'},
                    {'name': 'user_id', 'type': 'STRING'},
                    {'name': 'page', 'type': 'STRING'},
                    {'name': 'section', 'type': 'STRING'},
                    {'name': 'referrer', 'type': 'STRING'},
                    {'name': 'browser', 'type': 'STRING'},
                    {'name': 'os', 'type': 'STRING'},
                    {'name': 'device', 'type': 'STRING'},
                    {'name': 'ts', 'type': 'INTEGER'},
                    {'name': 'datetime', 'type': 'TIMESTAMP'}
                ]
            },
            'hivePartitioningOptions': {
                'mode': 'AUTO',
                'sourceUriPrefix': f'gs://{GCS_BUCKET}/page_view_events/',
            }
        }
    },
    dag=dag
)

# Create external table for auth_events
create_auth_events_table = BigQueryCreateExternalTableOperator(
    task_id='create_auth_events_table',
    table_resource={
        'tableReference': {
            'projectId': GCP_PROJECT_ID,
            'datasetId': BIGQUERY_DATASET,
            'tableId': 'ext_auth_events',
        },
        'externalDataConfiguration': {
            'sourceFormat': 'NEWLINE_DELIMITED_JSON',
            'sourceUris': [f'gs://{GCS_BUCKET}/auth_events/*.json'],
            'schema': {
                'fields': [
                    {'name': 'auth_id', 'type': 'STRING'},
                    {'name': 'user_id', 'type': 'STRING'},
                    {'name': 'level', 'type': 'STRING'},
                    {'name': 'method', 'type': 'STRING'},
                    {'name': 'status', 'type': 'STRING'},
                    {'name': 'ts', 'type': 'INTEGER'},
                    {'name': 'datetime', 'type': 'TIMESTAMP'}
                ]
            },
            'hivePartitioningOptions': {
                'mode': 'AUTO',
                'sourceUriPrefix': f'gs://{GCS_BUCKET}/auth_events/',
            }
        }
    },
    dag=dag
)

# Determine the order of execution
create_listen_events_table >> create_page_view_events_table >> create_auth_events_table
