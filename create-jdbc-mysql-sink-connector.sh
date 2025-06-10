#!/bin/bash

echo "⏳ Creando conector JDBC Sink hacia MySQL..."

curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d '{
    "name": "jdbc-connector",
    "config": {
        "connector.class": "io.debezium.connector.jdbc.JdbcSinkConnector",
        "tasks.max": "1",
        "connection.url": "jdbc:mysql://localhost:3306/jdbc_copia",
        "connection.username": "debezium",
        "connection.password": "dbz",
        "insert.mode": "upsert",
        "delete.enabled": "true",
        "primary.key.mode": "record_key",
        "schema.evolution": "basic",
        "use.time.zone": "America/Bogota",
        "topics": "Analytic.zalvadora_local_2.users",
        "field.include.list": "id, firstname, lastname, email, status"
    }
  }'

echo -e "\n✅ Conector creado para enviar datos a MySQL."
