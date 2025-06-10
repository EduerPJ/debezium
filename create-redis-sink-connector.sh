#!/bin/bash

echo "⏳ Creando conector Redis Sink para cache..."

curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d '{
    "name": "redis-sink-cache",
    "config": {
        "connector.class": "com.github.jcustenborder.kafka.connect.redis.RedisSinkConnector",
        "tasks.max": "1",
        "topics": "AnalyticdbOpt.zalvadora_local_2.users",
        "redis.hosts": "IP:6379",
        "redis.database": "4",
        "redis.key.template": "user:${id}",
        "redis.value.template": "{\"id\":\"${id}\",\"firstname\":\"${firstname}\",\"lastname\":\"${lastname}\",\"email\":\"${email}\",\"status\":\"${status}\"}",
        "transforms": "unwrap,selectFields",
        "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
        "transforms.unwrap.drop.tombstones": "true",
        "transforms.unwrap.delete.handling.mode": "drop",
        "transforms.selectFields.type": "org.apache.kafka.connect.transforms.ReplaceField$Value",
        "transforms.selectFields.whitelist": "id,firstname,lastname,email,status",
        "consumer.override.auto.offset.reset": "earliest",
        "consumer.override.max.poll.records": "1000",
        "batch.size": "500",
        "errors.tolerance": "all",
        "errors.deadletterqueue.topic.name": "dlq-redis-errors",
        "errors.deadletterqueue.topic.replication.factor": "1"
    }
  }'

echo -e "\n✅ Conector Redis creado para cache en tiempo real."
