#!/bin/bash

echo "🔍 Verificando estado de la pipeline Debezium..."
echo "================================================"

echo -e "\n📋 CONECTORES REGISTRADOS:"
curl -s http://localhost:8083/connectors | jq -r '.[]' 2>/dev/null || curl -s http://localhost:8083/connectors

echo -e "\n📊 ESTADO DEL CONECTOR MYSQL SOURCE:"
curl -s http://localhost:8083/connectors/mysql-source/status | jq . 2>/dev/null || curl -s http://localhost:8083/connectors/mysql-source/status

echo -e "\n📊 ESTADO DEL CONECTOR JDBC SINK:"
curl -s http://localhost:8083/connectors/jdbc-connector/status | jq . 2>/dev/null || curl -s http://localhost:8083/connectors/jdbc-connector/status

echo -e "\n📝 TOPICS DISPONIBLES:"
docker exec -it $(docker ps -q --filter name=kafka) kafka-topics --bootstrap-server localhost:9092 --list 2>/dev/null || echo "No se puede conectar a Kafka"

echo -e "\n🔍 VERIFICANDO TOPICS DEBEZIUM:"
docker exec -it $(docker ps -q --filter name=kafka) kafka-topics --bootstrap-server localhost:9092 --list | grep -i zalvadora 2>/dev/null || echo "No se encontraron topics de zalvadora"

echo -e "\n✅ Verificación completada"