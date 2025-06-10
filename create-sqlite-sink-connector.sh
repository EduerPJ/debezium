#!/bin/bash

echo "⏳ Creando conector JDBC Sink hacia SQLite..."

curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d '{
    "name": "sqlite-sink",
    "config": {
      "connector.class": "io.confluent.connect.jdbc.JdbcSinkConnector",
      "tasks.max": "1",
      "topics": "Analytic.zalvadora_local_2.users",
      "connection.url": "jdbc:sqlite:/data/cambios.db",
      "auto.create": "true",
      "auto.evolve": "true",
      "insert.mode": "upsert",
      "delete.enabled": "true",
      "pk.mode": "record_key",
      "pk.fields": "id",
      "transforms": "unwrap,flatten",
      "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
      "transforms.unwrap.drop.tombstones": "false",
      "transforms.unwrap.delete.handling.mode": "rewrite",
      "transforms.flatten.type": "org.apache.kafka.connect.transforms.Flatten$Value",
      "transforms.flatten.delimiter": "_",
      "behavior.on.null.values": "ignore",
      "behavior.on.malformed.messages": "warn",
      "max.retries": "10",
      "retry.backoff.ms": "3000"
    }
  }'

echo -e "\n✅ Conector creado para enviar datos a SQLite."
