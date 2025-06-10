#!/bin/bash

echo "⏳ Creando conector Debezium MySQL..."

curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d '{
    "name": "mysql-source",
    "config": {
      "connector.class": "io.debezium.connector.mysql.MySqlConnector",
      "database.hostname": "192.168.101.6",
      "database.port": "3306",
      "database.user": "debezium",
      "database.password": "dbz",
      "database.server.id": "85744",
      "database.server.name": "mysql_server",
      "topic.prefix": "Analyticdb1",
      "database.include.list": "zalvadora_local_2",
      "table.include.list": "zalvadora_local_2.users",
      "table.exclude.list": "zalvadora_local_2\\.*",
      "column.include.list": "id, firstname, lastname, email, status",
      "schema.history.internal.kafka.bootstrap.servers": "kafka:9092",
      "schema.history.internal.kafka.topic": "schema-changes.zalvadora_local_2",
      "custom.metric.tags": "k1=v1",
      "event.converting.failure.handling.mode": "skip"
    }
  }'

echo -e "\n✅ Conector creado (si todo salió bien)."
