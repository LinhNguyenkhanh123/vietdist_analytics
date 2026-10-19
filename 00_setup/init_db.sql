CREATE TABLE raw.ingest_log (
    log_id BIGSERIAL PRIMARY KEY,
    batch_id UUID NOT NULL,
    source_name TEXT,
    source_file TEXT,
    source_platform TEXT,
    file_id TEXT,
    file_modified_time TEXT,
    rows_loaded INT,
    status TEXT CHECK (status IN ('SUCCESS', 'FAILED', 'SKIPPED')),
    error_message TEXT,
    duration_sec NUMERIC(10, 2),
    logged_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX ix_ingest_log_lookup
    ON raw.ingest_log (source_name, file_id, file_modified_time, status);