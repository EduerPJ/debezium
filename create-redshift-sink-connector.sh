#!/bin/bash

echo "⏳ Creando conector JDBC Sink hacia RedShift..."

curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d '{
    "name": "redshift-sink",
    "config": {
      "connector.class": "io.confluent.connect.jdbc.JdbcSinkConnector",
      "tasks.max": "1",
      "topics": "AnalyticdbOpt.zalvadora_local_2.users",
      "connection.url": "jdbc:redshift://zalvadora-lxp-analitica.822218623501.us-east-2.redshift-serverless.amazonaws.com:5439/dev",
      "connection.user": "${REDSHIFT_USER}",
      "connection.password": "{$REDSHIFT_PASSWORD}",
      "auto.create": "true",
      "auto.evolve": "true",
      "insert.mode": "upsert",
      "pk.mode": "record_value",
      "pk.fields": "id",
      "transforms": "unwrap,selectFields",
      "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
      "transforms.unwrap.drop.tombstones": "true",
      "transforms.unwrap.delete.handling.mode": "drop",
      "transforms.selectFields.type": "org.apache.kafka.connect.transforms.ReplaceField$Value",
      "transforms.selectFields.whitelist": "id,firstname,lastname,email,status",
      "consumer.override.auto.offset.reset": "earliest",
      "consumer.override.max.poll.records": "1000",
      "batch.size": "500",
      "errors.tolerance": "all",
      "errors.deadletterqueue.topic.name": "dlq-redshift-errors",
      "errors.deadletterqueue.topic.replication.factor": "1"
    }
  }'

echo -e "\n✅ Conector RedShift creado."