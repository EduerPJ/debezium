# Guía Completa: Configuración de Debezium CDC (Change Data Capture)

Esta guía te permitirá configurar un sistema completo de captura de cambios de datos desde MySQL hacia SQLite usando Debezium, Kafka y Docker.

## 📋 Prerrequisitos

- **Docker** y **Docker Compose** instalados
- **MySQL 5.7+** o **XAMPP/LAMPP** 
- **Puertos disponibles**: 3306, 8080, 8081, 8083, 9092, 2181
- **Usuario con permisos** sudo/admin
- **Mínimo 4GB RAM** recomendado

---

## 🗂️ Paso 1: Crear Estructura del Proyecto

```bash
# Crear directorio principal
mkdir -p debezium-cdc/data/plugins
cd debezium-cdc

# Descargar driver SQLite
cd data/plugins
wget https://repo1.maven.org/maven2/org/xerial/sqlite-jdbc/3.44.1.0/sqlite-jdbc-3.44.1.0.jar
cd ../..
```

---

## 📄 Paso 2: Crear docker-compose.yml

```yaml
services:

  zookeeper:
    image: confluentinc/cp-zookeeper:7.5.0
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
    ports:
      - "2181:2181"

  kafka:
    image: confluentinc/cp-kafka:7.5.0
    depends_on:
      - zookeeper
    ports:
      - "9092:9092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1

  connect:
    image: quay.io/debezium/connect:2.5
    user: root
    command:
      - bash
      - -c
      - |
        # Download and install JDBC connector
        cd /tmp
        curl -L -o kafka-connect-jdbc-10.7.4.jar https://packages.confluent.io/maven/io/confluent/kafka-connect-jdbc/10.7.4/kafka-connect-jdbc-10.7.4.jar
        mkdir -p /kafka/connect/jdbc
        cp kafka-connect-jdbc-10.7.4.jar /kafka/connect/jdbc/
        
        # Copy SQLite driver to JDBC directory
        cp /kafka/connect/sqlite-jdbc-3.44.1.0.jar /kafka/connect/jdbc/
        
        # Download and install Debezium MySQL connector
        curl -L -o debezium-connector-mysql-2.5.0.Final-plugin.tar.gz https://repo1.maven.org/maven2/io/debezium/debezium-connector-mysql/2.5.0.Final/debezium-connector-mysql-2.5.0.Final-plugin.tar.gz
        mkdir -p /kafka/connect/debezium-mysql
        tar -xzf debezium-connector-mysql-2.5.0.Final-plugin.tar.gz -C /kafka/connect/debezium-mysql --strip-components=1

        # Start Kafka Connect
        /docker-entrypoint.sh start
    depends_on:
      - kafka
    ports:
      - "8083:8083"
    environment:
      BOOTSTRAP_SERVERS: kafka:9092
      GROUP_ID: 1
      CONFIG_STORAGE_TOPIC: debezium_connect_configs
      OFFSET_STORAGE_TOPIC: debezium_connect_offsets
      STATUS_STORAGE_TOPIC: debezium_connect_statuses
      CONFIG_STORAGE_REPLICATION_FACTOR: 1
      OFFSET_STORAGE_REPLICATION_FACTOR: 1
      STATUS_STORAGE_REPLICATION_FACTOR: 1
      KEY_CONVERTER: org.apache.kafka.connect.json.JsonConverter
      VALUE_CONVERTER: org.apache.kafka.connect.json.JsonConverter
      CONNECT_REST_ADVERTISED_HOST_NAME: connect
      CONNECT_PLUGIN_PATH: /kafka/connect,/kafka/external_libs
    volumes:
      - ./data:/data
      - ./data/plugins:/kafka/connect

  kafka-ui:
    image: provectuslabs/kafka-ui:latest
    depends_on:
      - kafka
    ports:
      - "8080:8080"
    environment:
      KAFKA_CLUSTERS_0_NAME: default
      KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS: kafka:9092

  sqlite-shell:
    image: nouchka/sqlite3:latest
    container_name: sqlite-shell
    volumes:
      - ./data:/data
    entrypoint: tail -f /dev/null

  sqlite-web:
      image: coleifer/sqlite-web
      container_name: sqlite-web
      depends_on:
        - connect
      ports:
        - "8081:8080"
      volumes:
        - ./data:/root/sqlite
      working_dir: /root/sqlite
      command: ["sqlite_web", "--host", "0.0.0.0", "cambios.db"]
```

---

## 🗄️ Paso 3: Configurar MySQL

### 3.1 Configurar Binary Logging

**Para XAMPP/LAMPP:**
```bash
# Editar archivo de configuración
sudo nano /opt/lampp/etc/my.cnf

# Agregar estas líneas en la sección [mysqld]:
[mysqld]
server-id=12345
log_bin=mysql-bin
binlog_format=row
binlog_row_image=full
expire_logs_days=7
```

**Para MySQL standalone:**
```bash
# Editar my.cnf (ubicación varía por SO)
sudo nano /etc/mysql/my.cnf
# o
sudo nano /etc/my.cnf

# Agregar las mismas líneas [mysqld]
```

### 3.2 Reiniciar MySQL

**XAMPP/LAMPP:**
```bash
sudo /opt/lampp/lampp restart mysql
```

**MySQL standalone:**
```bash
# Ubuntu/Debian
sudo systemctl restart mysql

# CentOS/RHEL
sudo systemctl restart mysqld

# macOS (Homebrew)
brew services restart mysql
```

### 3.3 Crear Usuario Debezium

```sql
-- Conectarse como root
mysql -u root -p
# o para XAMPP: /opt/lampp/bin/mysql -u root -p

-- Crear usuario y permisos
CREATE USER IF NOT EXISTS 'debezium'@'%' IDENTIFIED BY 'dbz';
CREATE USER IF NOT EXISTS 'debezium'@'localhost' IDENTIFIED BY 'dbz';

GRANT SELECT, RELOAD, SHOW DATABASES, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'debezium'@'%';
GRANT SELECT, RELOAD, SHOW DATABASES, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'debezium'@'localhost';

-- Permisos específicos en tu base de datos (cambiar 'tu_base_datos')
GRANT ALL PRIVILEGES ON tu_base_datos.* TO 'debezium'@'%';
GRANT ALL PRIVILEGES ON tu_base_datos.* TO 'debezium'@'localhost';

FLUSH PRIVILEGES;

-- Verificar usuario creado
SELECT User, Host FROM mysql.user WHERE User = 'debezium';

-- Verificar binlog activo
SHOW VARIABLES LIKE 'log_bin';
SHOW VARIABLES LIKE 'binlog_format';
```

### 3.4 Probar Conectividad

```bash
# Probar conexión del usuario debezium
mysql -u debezium -pdbz -h localhost -P 3306 -e "SELECT 1; SHOW DATABASES;"
# o para XAMPP: /opt/lampp/bin/mysql -u debezium -pdbz -h localhost -P 3306 -e "SELECT 1"
```

---

## 📜 Paso 4: Crear Scripts de Conectores

### 4.1 create-mysql-source-connector.sh

```bash
#!/bin/bash

echo "⏳ Creando conector Debezium MySQL..."

# IMPORTANTE: Cambiar IP_DE_TU_HOST por tu IP real
# Para obtener tu IP: hostname -I | awk '{print $1}'

curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d '{
    "name": "mysql-source",
    "config": {
      "connector.class": "io.debezium.connector.mysql.MySqlConnector",
      "database.hostname": "IP_DE_TU_HOST",
      "database.port": "3306",
      "database.user": "debezium",
      "database.password": "dbz",
      "database.server.id": "85744",
      "topic.prefix": "tu_base_datos",
      "database.include.list": "tu_base_datos",
      "include.schema.changes": "true",
      "schema.history.internal.kafka.bootstrap.servers": "kafka:9092",
      "schema.history.internal.kafka.topic": "schema-changes.tu_base_datos"
    }
  }'

echo -e "\n✅ Conector MySQL creado."
```

### 4.2 create-sqlite-sink-connector.sh

```bash
#!/bin/bash

echo "⏳ Creando conector JDBC Sink hacia SQLite..."

curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d '{
    "name": "sqlite-sink",
    "config": {
      "connector.class": "io.confluent.connect.jdbc.JdbcSinkConnector",
      "tasks.max": "1",
      "topics": "tu_base_datos.tabla1,tu_base_datos.tabla2",
      "connection.url": "jdbc:sqlite:/data/cambios.db",
      "auto.create": "true",
      "auto.evolve": "true",
      "insert.mode": "insert",
      "pk.mode": "record_value",
      "pk.fields": "id",
      "transforms": "flatten",
      "transforms.flatten.type": "org.apache.kafka.connect.transforms.Flatten$Value",
      "transforms.flatten.delimiter": "_"
    }
  }'

echo -e "\n✅ Conector SQLite creado."
```

### 4.3 Hacer scripts ejecutables

```bash
chmod +x create-mysql-source-connector.sh
chmod +x create-sqlite-sink-connector.sh
```

---

## 🚀 Paso 5: Configuración Específica por Ambiente

### 5.1 Obtener IP Local

```bash
# Obtener tu IP local
hostname -I | awk '{print $1}'
# o
ip route get 1 | awk '{print $7; exit}'
```

### 5.2 Personalizar Scripts

**Editar `create-mysql-source-connector.sh`:**
```bash
# Reemplazar:
"database.hostname": "IP_DE_TU_HOST"        # Por tu IP real
"topic.prefix": "tu_base_datos"             # Por nombre de tu BD
"database.include.list": "tu_base_datos"    # Por nombre de tu BD
```

**Editar `create-sqlite-sink-connector.sh`:**
```bash
# Reemplazar:
"topics": "tu_base_datos.tabla1,tu_base_datos.tabla2"  # Por tus tablas reales
```

---

## 🏃 Paso 6: Ejecutar el Sistema

### 6.1 Levantar Servicios

```bash
# Iniciar todos los contenedores
docker compose up -d

# Verificar que estén corriendo
docker compose ps

# Ver logs si hay problemas
docker compose logs connect
```

### 6.2 Esperar a que Connect esté listo

```bash
# Esperar ~2 minutos, luego verificar plugins disponibles
curl http://localhost:8083/connector-plugins | grep -i mysql
```

**Deberías ver**: `io.debezium.connector.mysql.MySqlConnector`

---

## 🔌 Paso 7: Crear Conectores

### 7.1 Crear Conector MySQL

```bash
./create-mysql-source-connector.sh

# Verificar estado
curl http://localhost:8083/connectors/mysql-source/status
```

**Estado esperado**: `"state": "RUNNING"`

### 7.2 Crear Conector SQLite

```bash
./create-sqlite-sink-connector.sh

# Verificar estado
curl http://localhost:8083/connectors/sqlite-sink/status
```

**Estado esperado**: `"state": "RUNNING"`

---

## 🧪 Paso 8: Probar el Sistema

### 8.1 Realizar Cambios en MySQL

```sql
-- Conectarse a MySQL
mysql -u root -p tu_base_datos

-- Hacer cambios de prueba
INSERT INTO tabla1 (columna1, columna2) VALUES ('Test CDC', 'test@cdc.com');
UPDATE tabla1 SET columna2 = 'updated@cdc.com' WHERE columna1 = 'Test CDC';
DELETE FROM tabla1 WHERE columna1 = 'Test CDC';
```

### 8.2 Verificar Datos en SQLite

**Via Web Interface:**
- **SQLite Web**: http://localhost:8081
- **Kafka UI**: http://localhost:8080

**Via Comando:**
```bash
# Acceder al contenedor SQLite
docker exec -it sqlite-shell sqlite3 /data/cambios.db

# Ver tablas creadas
.tables

# Ver datos capturados
SELECT * FROM tu_base_datos_tabla1 ORDER BY __ts_ms DESC LIMIT 5;
```

---

## 📊 Paso 9: Interfaces de Monitoreo

### 9.1 URLs Disponibles

- **Kafka UI**: http://localhost:8080
  - Ver topics, mensajes, consumers
  - Monitorear flujo de datos

- **SQLite Web**: http://localhost:8081
  - Explorar base SQLite
  - Ejecutar queries
  - Ver datos capturados

- **Kafka Connect REST**: http://localhost:8083
  - Gestionar conectores
  - Ver estados y configuraciones

### 9.2 Comandos Útiles de API

```bash
# Listar conectores
curl http://localhost:8083/connectors

# Ver estado de conector
curl http://localhost:8083/connectors/mysql-source/status

# Ver configuración
curl http://localhost:8083/connectors/mysql-source/config

# Reiniciar conector
curl -X POST http://localhost:8083/connectors/mysql-source/restart

# Eliminar conector
curl -X DELETE http://localhost:8083/connectors/mysql-source
```

---

## 🔧 Troubleshooting Común

### Error: "Communications link failure"

**Problema**: Docker no puede conectar con MySQL

**Soluciones**:
1. Verificar que MySQL esté corriendo: `netstat -tlnp | grep 3306`
2. Verificar IP en el script: `hostname -I`
3. Probar conectividad: `mysql -u debezium -pdbz -h IP -P 3306`

### Error: "Access denied for user 'debezium'"

**Problema**: Usuario no configurado correctamente

**Solución**:
```sql
DROP USER IF EXISTS 'debezium'@'%';
CREATE USER 'debezium'@'%' IDENTIFIED BY 'dbz';
GRANT SELECT, RELOAD, SHOW DATABASES, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'debezium'@'%';
FLUSH PRIVILEGES;
```

### Error: "No suitable driver found for jdbc:sqlite"

**Problema**: Driver SQLite no está en el lugar correcto

**Solución**:
```bash
# Verificar que el archivo esté en data/plugins/
ls -la data/plugins/sqlite-jdbc-3.44.1.0.jar

# Reiniciar connect
docker compose restart connect
```

### Error: "STRUCT type doesn't have a mapping"

**Problema**: Tipos de datos complejos en MySQL

**Solución**: Usar transformaciones `Flatten` (ya incluidas en el script)

---

## 🏭 Configuración para Producción

### Variables de Entorno

Crear archivo `.env`:

```env
# Configuración de memoria
KAFKA_HEAP_OPTS=-Xmx2G -Xms2G
CONNECT_HEAP_OPTS=-Xmx2G -Xms2G

# Configuración de base de datos
MYSQL_HOST=tu-servidor-mysql.com
MYSQL_USER=debezium
MYSQL_PASSWORD=tu-password-seguro
DATABASE_NAME=tu_base_datos

# Configuración de red
HOST_IP=192.168.1.100
```

### Configuraciones de Seguridad

```yaml
# Agregar al docker-compose.yml
environment:
  CONNECT_SECURITY_PROTOCOL: SSL
  CONNECT_SSL_KEYSTORE_LOCATION: /etc/kafka/secrets/kafka.keystore.jks
  CONNECT_SSL_KEYSTORE_PASSWORD: tu-password
```

### Persistencia de Datos

```yaml
# Agregar volúmenes persistentes
volumes:
  kafka-data:
  zookeeper-data:
  
services:
  kafka:
    volumes:
      - kafka-data:/var/lib/kafka/data
  
  zookeeper:
    volumes:
      - zookeeper-data:/var/lib/zookeeper
```

---

## ✅ Lista de Verificación Final

**Antes de comenzar**:
- [ ] Docker y Docker Compose instalados
- [ ] MySQL corriendo con binlog habilitado
- [ ] Puertos 3306, 8080, 8081, 8083, 9092, 2181 disponibles
- [ ] Usuario `debezium` creado con permisos

**Durante la configuración**:
- [ ] Estructura de directorios creada
- [ ] Driver SQLite descargado
- [ ] docker-compose.yml configurado
- [ ] Scripts personalizados con IP y nombres reales
- [ ] Permisos de ejecución en scripts

**Después de levantar**:
- [ ] Todos los contenedores RUNNING
- [ ] Plugins MySQL y JDBC disponibles
- [ ] Ambos conectores en estado RUNNING
- [ ] Cambios en MySQL aparecen en SQLite Web
- [ ] Interfaces web accesibles

---

## 🎯 Resumen de Funcionamiento

1. **MySQL**: Genera binlogs con cambios de datos
2. **Debezium MySQL Connector**: Lee binlogs y publica a Kafka topics
3. **Kafka**: Almacena y distribuye mensajes de cambios
4. **JDBC Sink Connector**: Consume de Kafka y escribe a SQLite
5. **SQLite**: Base de datos de destino con cambios replicados

**¡Tu sistema CDC está completo!** 🎉

---

## 📞 Soporte

Para más información:
- [Documentación Debezium](https://debezium.io/documentation/)
- [Kafka Connect](https://kafka.apache.org/documentation/#connect)
- [Confluent JDBC Connector](https://docs.confluent.io/kafka-connect-jdbc/current/)