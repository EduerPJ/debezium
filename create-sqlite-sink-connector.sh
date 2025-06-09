#!/bin/bash

echo "⏳ Creando conector JDBC Sink hacia SQLite..."

curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d '{
    "name": "sqlite-sink",
    "config": {
      "connector.class": "io.confluent.connect.jdbc.JdbcSinkConnector",
      "tasks.max": "1",
      "topics": "zalvadora_local_2.users",
      "connection.url": "jdbc:sqlite:/data/cambios.db",
      "auto.create": "true",
      "auto.evolve": "true",
      "insert.mode": "upsert",
      "pk.mode": "record_key",
      "pk.fields": "id",
      "transforms": "flatten",
      "transforms.flatten.type": "org.apache.kafka.connect.transforms.Flatten$Value",
      "transforms.flatten.delimiter": "_"
    }
  }'

echo -e "\n✅ Conector creado para enviar datos a SQLite."
