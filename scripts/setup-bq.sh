#!/bin/bash

#Create BQ Dataset
bq --location=$GCP_REGION mk \
    --dataset \
    --description="Each row of this table represents a Transcoder Job initiated by an upload to the Google Cloud Storage (GCS) bucket or by bulk upload in the Workflow UI." \
    --label "env:transcoding" \
    "$PROJECT_ID:transcoder_jobs_$CUSTOMER_ID"

# Create a BigQuery Table to house job metadata from the Workflow
bq mk \
--table \
--label env:transcoding \
"$PROJECT_ID:transcoder_jobs_$CUSTOMER_ID.jobs" \
"../analytics/bq-job-stats-schema.json"

# Create BQ Table for Log Events: GKE
bq mk \
--table \
--label env:logs \
"$PROJECT_ID:transcoder_jobs_$CUSTOMER_ID.log-events-gke" \
"../analytics/bq-log-events-gke-schema.json"

# Create BQ Table for Log Events: Batch API
bq mk \
--table \
--label env:logs \
"$PROJECT_ID:transcoder_jobs_$CUSTOMER_ID.log-events-batch" \
"../analytics/bq-log-events-gke-schema.json"

#Create a BigQuery connection to the rest of the GCP Resources
bq mk \
--connection \
--location=$GCP_REGION \
    --connection_type=CLOUD_RESOURCE "bq-biglake-gcp-resources"

# Create a BigQuery object table with manual metadata caching.
bq mkdef --connection_id=$PROJECT_ID.$GCP_REGION.bq-biglake-gcp-resources-script \
--noautodetect \
--object_metadata="SIMPLE" \
--metadata_cache_mode="MANUAL" \
gs://$SOURCE_GCS/* > def_input_file

bq mk --table \
  --external_table_definition=def_input_file \
  "transcoder_jobs_$CUSTOMER_ID.gcs-objects-input"

# Create a BigQuery object table with manual metadata caching.
bq mkdef --connection_id=$PROJECT_ID.$GCP_REGION.bq-biglake-gcp-resources-script \
--noautodetect \
--object_metadata="SIMPLE" \
--metadata_cache_mode="MANUAL" \
gs://$OUTPUT_GCS/* > def_output_file

bq mk --table \
  --external_table_definition=def_output_file \
  "transcoder_jobs_$CUSTOMER_ID.gcs-objects-output"

# A view that combines Job statistics, input, and output information
bq mk \
--use_legacy_sql=false \
--view \
'SELECT
    j.JobId,
    j.createdDateTime,
    j.BackendSrv,
    input.URI as input_file_uri,
    input.generation as input_file_generation,
    input.content_type as input_file_content_type,
    input.size as input_file_content_size,
    ARRAY_AGG(STRUCT(
        output.URI,
        output.generation,
        output.content_type,
        output.size
    )) AS output_files,
    ARRAY_CONCAT(IFNULL(gke_events.Events, []), IFNULL(batch_events.Events, [])) AS Events
FROM `'transcoder_jobs_${CUSTOMER_ID}.jobs'` AS j
LEFT JOIN `'transcoder_jobs_${CUSTOMER_ID}.gcs-objects-input'` AS input 
    ON j.FileURI = input.URI
LEFT JOIN (
    SELECT
        URI,
        SPLIT(URI, "/") AS URI_PARTS,
        generation,
        content_type,
        size
    FROM
        `'transcoder_jobs_${CUSTOMER_ID}.gcs-objects-output'`
    ) AS output
ON
    output.URI_PARTS[SAFE_OFFSET(2)] = "${OUTPUT_GCS}"
    AND output.URI_PARTS[SAFE_OFFSET(3)] = j.BackendSrv
    AND output.URI_PARTS[SAFE_OFFSET(4)] = j.JobId
LEFT JOIN (
    SELECT 
        JobId,
        ARRAY_AGG(STRUCT(LogName, Status, TimeStamp) IGNORE NULLS) AS Events
    FROM `'transcoder_jobs_${CUSTOMER_ID}.log-events-gke'`
    GROUP BY JobId
) AS gke_events USING(JobId)
LEFT JOIN (
    SELECT 
        JobId,
        ARRAY_AGG(STRUCT(LogName, Status, TimeStamp) IGNORE NULLS) AS Events
    FROM `'transcoder_jobs_${CUSTOMER_ID}.log-events-batch'`
    GROUP BY JobId
) AS batch_events USING(JobId)
GROUP BY
  ALL' \
transcoder_jobs_$CUSTOMER_ID.job-stats-summary

# Create a set of scheduled BigQuery jobs to load data from logs
# Log Sink -> {various BigQuery table exports} -> Jobs-specific Events
bq query \
--use_legacy_sql=false \
--target_dataset="transcoder_jobs_$CUSTOMER_ID" \
--display_name='update-gke-log-events' \
--schedule='every 60 minutes' \
'INSERT INTO
    `'${PROJECT_ID}.transcoder_jobs_${CUSTOMER_ID}.log-events-gke'` (
    SELECT
        jobs.JobId,
        e.LogName,
        e.Status,
        e.Timestamp
    FROM
        `'${PROJECT_ID}.transcoder_jobs_${CUSTOMER_ID}.jobs'` AS jobs
    INNER JOIN (
        SELECT
            SPLIT(REPLACE(jsonPayload.metadata.name, "transcoding-", ""), ".")[SAFE_OFFSET(0)] AS JobId,
            logName AS LogName,
            jsonPayload.reason AS Status,
            PARSE_TIMESTAMP("%Y-%m-%dT%H:%M:%SZ", jsonPayload.lasttimestamp) AS Timestamp
        FROM
            # Log Sink export: events
            `'${PROJECT_ID}.transcoder_jobs_${CUSTOMER_ID}.events'`
        WHERE
            TIMESTAMP_TRUNC(timestamp, DAY) = TIMESTAMP(CURRENT_DATE())
            AND jsonPayload.source.component = "job-controller"
        GROUP BY
            ALL) AS e
    USING
        (JobId)
    LEFT JOIN
        `'${PROJECT_ID}.transcoder_jobs_${CUSTOMER_ID}.log-events-gke'` AS existing_e
    USING
        (JobId,
            LogName,
            Status,
            TimeStamp)
    WHERE
        existing_e.TimeStamp IS NULL)'

bq query \
--use_legacy_sql=false \
--target_dataset="transcoder_jobs_$CUSTOMER_ID" \
--display_name='update-batch-log-events' \
--schedule='every 60 minutes' \
'INSERT INTO
    `'${PROJECT_ID}.transcoder_jobs_${CUSTOMER_ID}.log-events-batch'` (
    SELECT
        jobs.JobId,
        e.LogName,
        e.Status,
        e.Timestamp
    FROM
        `'${PROJECT_ID}.transcoder_jobs_${CUSTOMER_ID}.jobs'` AS jobs
    INNER JOIN (
        SELECT
            abels.workflows_googleapis_com_execution_id AS JobId,
            logName AS LogName,
            jsonpayload_type_executionssystemlog.state AS Status,
            timestamp AS TimeStamp
        FROM
            `'${PROJECT_ID}.transcoder_jobs_${CUSTOMER_ID}.workflows_googleapis_com_executions_system'`
        WHERE
            TIMESTAMP_TRUNC(timestamp, DAY) = TIMESTAMP(CURRENT_DATE())
            AND resource.type = 'workflows.googleapis.com/Workflow'
        GROUP BY
            ALL ) AS e
        USING
            (JobId)
        LEFT JOIN
            `'${PROJECT_ID}.transcoder_jobs_${CUSTOMER_ID}.log-events-batch'` AS existing_e
        USING
            (JobId,
            LogName,
            Status,
            TimeStamp)
        WHERE
            existing_e.TimeStamp IS NULL)'