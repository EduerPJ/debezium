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
      "topic.prefix": "Analytic",
      "database.include.list": "zalvadora_local_2",
      "table.include.list": "zalvadora_local_2.users",
      "include.schema.changes": "true",
      "schema.history.internal.kafka.bootstrap.servers": "kafka:9092",
      "schema.history.internal.kafka.topic": "schema-changes.zalvadora_local_2",
      "database.allowPublicKeyRetrieval": "true",
      "snapshot.mode": "initial",
      "database.history.kafka.topic": "dbhistory.zalvadora_local_2",
      "tombstones.on.delete": "true",
      "snapshot.locking.mode": "none",
      "include.query": "true"
    }
  }'

echo -e "\n✅ Conector creado (si todo salió bien)."
