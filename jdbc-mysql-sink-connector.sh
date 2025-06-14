#!/bin/bash

echo "⏳ Creando conector JDBC Sink hacia MySQL..."

curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d '{
    "name": "jdbc-connector-optimized",
    "config": {
        "connector.class": "io.confluent.connect.jdbc.JdbcSinkConnector",
        "tasks.max": "1",
        "connection.url": "jdbc:mysql://192.168.101.9:3306/jdbc_copia?serverTimezone=America/Bogota&useSSL=false&allowPublicKeyRetrieval=true&rewriteBatchedStatements=true&cachePrepStmts=true",
        "connection.username": "root",
        "connection.password": "",
        "insert.mode": "upsert",
        "delete.enabled": "false",
        "pk.mode": "record_key",
        "auto.create": "true",
        "auto.evolve": "true",
        "table.name.format": "users",
        "topics": "Analitics.zalvadora_local_2.users",
        "consumer.override.auto.offset.reset": "earliest",
        "consumer.override.max.poll.records": "2000",
        "batch.size": "1000",
        "transforms": "unwrap,selectFields",
        "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
        "transforms.unwrap.drop.tombstones": "true",
        "transforms.unwrap.delete.handling.mode": "drop",
        "transforms.selectFields.type": "org.apache.kafka.connect.transforms.ReplaceField$Value",
        "transforms.selectFields.whitelist": "id,firstname,lastname,email,status",
        "errors.tolerance": "all",
        "errors.deadletterqueue.topic.name": "dlq-jdbc-errors",
        "errors.deadletterqueue.topic.replication.factor": "1"
    }
  }'

echo -e "\n⏳ Verificando estado del conector..."

curl -s http://localhost:8083/connectors/jdbc-connector-optimized/status | jq '.'

echo -e "\n✅ Conector creado para enviar datos a MySQL."
