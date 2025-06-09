#!/bin/bash

echo "⏳ Creando conector Debezium MySQL..."

curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d '{
    "name": "mysql-source",
    "config": {
      "connector.class": "io.debezium.connector.mysql.MySqlConnector",
      "database.hostname": "host.docker.internal",
      "database.port": "3306",
      "database.user": "debezium",
      "database.password": "dbz",
      "database.server.id": "85744",
      "database.server.name": "zalvadora_local_2",
      "database.include.list": "zalvadora_local_2",
      "include.schema.changes": "true",
      "database.history.kafka.bootstrap.servers": "kafka:9092",
      "database.history.kafka.topic": "schema-changes.zalvadora_local_2"
    }
  }'

echo -e "\n✅ Conector creado (si todo salió bien)."
