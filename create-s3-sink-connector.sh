#!/bin/bash

echo "⏳ Creando conector S3 Sink para Redshift..."

curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d '{
    "name": "s3-sink-redshift",
    "config": {
        "connector.class": "io.confluent.connect.s3.S3SinkConnector",
        "tasks.max": "1",
        "topics": "AnalyticdbOpt.zalvadora_local_2.users",
        "s3.region": "us-east-1",
        "s3.bucket.name": "your-redshift-bucket",
        "s3.part.size": "5242880",
        "flush.size": "1000",
        "rotate.interval.ms": "60000",
        "storage.class": "io.confluent.connect.s3.storage.S3Storage",
        "format.class": "io.confluent.connect.s3.format.parquet.ParquetFormat",
        "partitioner.class": "io.confluent.connect.storage.partitioner.TimeBasedPartitioner",
        "partition.duration.ms": "3600000",
        "path.format": "year=YYYY/month=MM/day=dd/hour=HH",
        "locale": "en-US",
        "timezone": "America/Bogota",
        "transforms": "unwrap,selectFields",
        "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
        "transforms.unwrap.drop.tombstones": "true",
        "transforms.unwrap.delete.handling.mode": "drop",
        "transforms.selectFields.type": "org.apache.kafka.connect.transforms.ReplaceField$Value",
        "transforms.selectFields.whitelist": "id,firstname,lastname,email,status",
        "aws.access.key.id": "YOUR_ACCESS_KEY",
        "aws.secret.access.key": "YOUR_SECRET_KEY"
    }
  }'

echo -e "\n✅ Conector S3 creado para pipeline hacia Redshift."
