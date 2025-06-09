# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture Overview

This is a Debezium-based data streaming pipeline that captures changes from a MySQL database and sinks them to SQLite. The architecture consists of:

- **Kafka ecosystem**: Zookeeper, Kafka broker, and Kafka Connect runtime
- **Debezium MySQL source connector**: Captures changes from `zalvadora_local_2` database
- **JDBC sink connector**: Writes changes to SQLite database (`cambios.db`)
- **Monitoring tools**: Kafka UI (port 8080) and SQLite Web (port 8081)

## Common Commands

### Starting the environment
```bash
docker-compose up -d
```

### Creating connectors
```bash
# Create MySQL source connector
./create-mysql-source-connector.sh

# Create SQLite sink connector  
./create-sqlite-sink-connector.sh
```

### Checking connector status
```bash
# List all connectors
curl http://localhost:8083/connectors

# Get specific connector status
curl http://localhost:8083/connectors/mysql-source/status
curl http://localhost:8083/connectors/sqlite-sink/status
```

### Accessing SQLite data
```bash
# Via container shell
docker exec -it sqlite-shell sqlite3 /data/cambios.db

# Via web interface
# Open http://localhost:8081 in browser
```

## Key Configuration Details

- MySQL source connects to `host.docker.internal:3306` with user `debezium`
- SQLite sink writes to `/data/cambios.db` (mounted volume)
- Kafka Connect REST API available at `localhost:8083`
- Topics follow pattern `zalvadora_local_2.*`
- SQLite JDBC driver located in `data/plugins/sqlite-jdbc-3.44.1.0.jar`