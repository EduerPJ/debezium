-- Redshift table schema for users analytics
CREATE TABLE IF NOT EXISTS analytics.users (
    id BIGINT NOT NULL,
    firstname VARCHAR(255),
    lastname VARCHAR(255),
    email VARCHAR(255),
    status SMALLINT,
    processed_at TIMESTAMP DEFAULT GETDATE(),
    partition_date DATE
)
DISTSTYLE KEY
DISTKEY (id)
SORTKEY (id, partition_date);

-- Create schema if needed
CREATE SCHEMA IF NOT EXISTS analytics;