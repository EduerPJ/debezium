#!/bin/bash

echo "⏳ Creando conector Debezium MySQL..."

curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d '{
    "name": "mysql-source",
    "config": {
      "connector.class": "io.debezium.connector.mysql.MySqlConnector",
      "database.hostname": "192.168.101.9",
      "database.port": "3306",
      "database.user": "debezium",
      "database.password": "dbz",
      "database.server.id": "85744",
      "database.server.name": "mysql_server",
      "topic.prefix": "Analyticdb1",
      "database.include.list": "zalvadora_local_2",
      "table.include.list": "zalvadora_local_2.users",
      "column.include.list": "zalvadora_local_2.users.id,zalvadora_local_2.users.firstname,zalvadora_local_2.users.lastname,zalvadora_local_2.users.email,zalvadora_local_2.users.status",
      "schema.history.internal.kafka.bootstrap.servers": "kafka:9092",
      "schema.history.internal.kafka.topic": "schema-changes.zalvadora_local_2",
      "snapshot.mode": "initial",
      "include.schema.changes": "false",
      "key.converter.schemas.enable": "false",
      "value.converter.schemas.enable": "false"
    }
  }'

echo -e "\n✅ Conector creado (si todo salió bien)."
