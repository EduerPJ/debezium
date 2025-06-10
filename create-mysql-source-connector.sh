#!/bin/bash

echo "⏳ Creando conector Debezium MySQL..."

curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d '{
    "name": "mysql-source-optimized",
    "config": {
      "connector.class": "io.debezium.connector.mysql.MySqlConnector",
      "database.hostname": "192.168.101.9",
      "database.port": "3306",
      "database.user": "debezium",
      "database.password": "dbz",
      "database.server.id": "85745",
      "database.server.name": "mysql_server_opt",
      "topic.prefix": "AnalyticdbOpt",
      "database.include.list": "zalvadora_local_2",
      "table.include.list": "zalvadora_local_2.users",
      "schema.history.internal.kafka.bootstrap.servers": "kafka:9092",
      "schema.history.internal.kafka.topic": "schema-changes.zalvadora_local_2_opt",
      "snapshot.mode": "initial",
      "snapshot.fetch.size": "10000",
      "incremental.snapshot.chunk.size": "2048",
      "max.batch.size": "2048",
      "max.queue.size": "8192",
      "include.schema.changes": "false",
      "key.converter.schemas.enable": "false",
      "value.converter.schemas.enable": "false",
      "provide.transaction.metadata": "false",
      "binary.handling.mode": "base64",
      "decimal.handling.mode": "double"
    }
  }'

echo -e "\n✅ Conector creado (si todo salió bien)."
