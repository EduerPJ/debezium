#!/bin/bash

echo "⏳ Creando conector JDBC Sink hacia SQLite..."

curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d '{
    "name": "sqlite-sink",
    "config": {
      "connector.class": "io.confluent.connect.jdbc.JdbcSinkConnector",
      "tasks.max": "1",
      "topics.regex": "zalvadora_local_2\\..*",
      "connection.url": "jdbc:sqlite:/data/cambios.db",
      "auto.create": "true",
      "insert.mode": "insert"
    }
  }'

echo -e "\n✅ Conector creado para enviar datos a SQLite."
