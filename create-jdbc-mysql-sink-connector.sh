#!/bin/bash

echo "⏳ Creando conector JDBC Sink hacia MySQL..."

curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d '{
    "name": "jdbc-connector",
    "config": {
        "connector.class": "io.confluent.connect.jdbc.JdbcSinkConnector",
        "tasks.max": "1",
        "connection.url": "jdbc:mysql://192.168.101.9:3306/jdbc_copia?serverTimezone=America/Bogota&useSSL=false&allowPublicKeyRetrieval=true",
        "connection.username": "root",
        "connection.password": "",
        "insert.mode": "upsert",
        "delete.enabled": "false",
        "pk.mode": "record_value",
        "pk.fields": "id",
        "auto.create": "true",
        "auto.evolve": "true",
        "table.name.format": "users",
        "topics": "Analyticdb1.zalvadora_local_2.users",
        "transforms": "unwrap",
        "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
        "transforms.unwrap.drop.tombstones": "false",
        "transforms.unwrap.delete.handling.mode": "none"
    }
  }'

echo -e "\n✅ Conector creado para enviar datos a MySQL."
