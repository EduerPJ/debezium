#!/bin/bash

echo "⏳ Creando conector Debezium MySQL..."

curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d '{
    "name": "mysql-source-optimized",
    "config": {
      "connector.class": "io.debezium.connector.mysql.MySqlConnector",
      "database.hostname": "${MYSQL_HOST}",
      "database.port": "${MYSQL_PORT}",
      "database.user": "${MYSQL_USER}",
      "database.password": "${MYSQL_PASSWORD}",
      "database.server.id": "${MYSQL_SERVER_ID}",
      "database.server.name": "${MYSQL_SERVER_NAME}",
      "topic.prefix": "${KAFKA_TOPIC_PREFIX}",
      "database.include.list": "${MYSQL_DATABASE}",
      "table.include.list": "${MYSQL_DATABASE}.users",
      "schema.history.internal.kafka.bootstrap.servers": "kafka:9092",
      "schema.history.internal.kafka.topic": "schema-changes.${MYSQL_DATABASE}_opt",
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
