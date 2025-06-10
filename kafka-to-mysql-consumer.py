#!/usr/bin/env python3
"""
Consumer personalizado que lee mensajes de Debezium desde Kafka
y los replica en jdbc_copia.users
"""

import json
import time
import logging
from kafka import KafkaConsumer
import mysql.connector
from mysql.connector import Error

# Configuración de logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Configuración de Kafka
KAFKA_BOOTSTRAP_SERVERS = ['localhost:9092']
KAFKA_TOPIC = 'Analyticdb1.zalvadora_local_2.users'
CONSUMER_GROUP = 'mysql-sink-consumer'

# Configuración de MySQL
MYSQL_CONFIG = {
    'host': 'localhost',
    'port': 3306,
    'user': 'root',
    'password': '',
    'database': 'jdbc_copia',
    'autocommit': True
}

def create_table_if_not_exists(cursor):
    """Crear tabla si no existe"""
    create_table_sql = """
    CREATE TABLE IF NOT EXISTS users (
        id INT PRIMARY KEY,
        firstname VARCHAR(100),
        lastname VARCHAR(100),
        email VARCHAR(100),
        status TINYINT,
        INDEX idx_email (email)
    )
    """
    cursor.execute(create_table_sql)
    logger.info("Tabla 'users' verificada/creada")

def process_debezium_message(message_value, cursor):
    """Procesar mensaje de Debezium"""
    try:
        # Parsear el mensaje JSON
        data = json.loads(message_value.decode('utf-8'))
        
        # Obtener la operación
        operation = data.get('op')
        
        if operation == 'c':  # CREATE (INSERT)
            after_data = data.get('after', {})
            if after_data:
                insert_sql = """
                INSERT INTO users (id, firstname, lastname, email, status) 
                VALUES (%(id)s, %(firstname)s, %(lastname)s, %(email)s, %(status)s)
                ON DUPLICATE KEY UPDATE 
                firstname = VALUES(firstname),
                lastname = VALUES(lastname),
                email = VALUES(email),
                status = VALUES(status)
                """
                cursor.execute(insert_sql, {
                    'id': after_data.get('id'),
                    'firstname': after_data.get('firstname'),
                    'lastname': after_data.get('lastname'),
                    'email': after_data.get('email'),
                    'status': after_data.get('status')
                })
                logger.info(f"INSERTED/UPDATED: id={after_data.get('id')}, email={after_data.get('email')}")
                
        elif operation == 'u':  # UPDATE
            after_data = data.get('after', {})
            if after_data:
                update_sql = """
                UPDATE users SET 
                firstname = %(firstname)s,
                lastname = %(lastname)s,
                email = %(email)s,
                status = %(status)s
                WHERE id = %(id)s
                """
                cursor.execute(update_sql, {
                    'id': after_data.get('id'),
                    'firstname': after_data.get('firstname'),
                    'lastname': after_data.get('lastname'),
                    'email': after_data.get('email'),
                    'status': after_data.get('status')
                })
                logger.info(f"UPDATED: id={after_data.get('id')}, email={after_data.get('email')}")
                
        elif operation == 'd':  # DELETE
            before_data = data.get('before', {})
            if before_data and before_data.get('id'):
                delete_sql = "DELETE FROM users WHERE id = %(id)s"
                cursor.execute(delete_sql, {'id': before_data.get('id')})
                logger.info(f"DELETED: id={before_data.get('id')}")
                
        elif operation == 'r':  # READ (snapshot)
            after_data = data.get('after', {})
            if after_data:
                # Solo procesar si tiene datos reales
                if after_data.get('id') and after_data.get('email'):
                    insert_sql = """
                    INSERT INTO users (id, firstname, lastname, email, status) 
                    VALUES (%(id)s, %(firstname)s, %(lastname)s, %(email)s, %(status)s)
                    ON DUPLICATE KEY UPDATE 
                    firstname = VALUES(firstname),
                    lastname = VALUES(lastname),
                    email = VALUES(email),
                    status = VALUES(status)
                    """
                    cursor.execute(insert_sql, {
                        'id': after_data.get('id'),
                        'firstname': after_data.get('firstname'),
                        'lastname': after_data.get('lastname'),
                        'email': after_data.get('email'),
                        'status': after_data.get('status')
                    })
                    logger.info(f"SNAPSHOT: id={after_data.get('id')}, email={after_data.get('email')}")
                    
    except Exception as e:
        logger.error(f"Error procesando mensaje: {e}")
        logger.error(f"Mensaje: {message_value}")

def main():
    logger.info("Iniciando consumer Kafka -> MySQL")
    
    # Conectar a MySQL
    try:
        mysql_conn = mysql.connector.connect(**MYSQL_CONFIG)
        cursor = mysql_conn.cursor()
        create_table_if_not_exists(cursor)
        logger.info("Conectado a MySQL")
    except Error as e:
        logger.error(f"Error conectando a MySQL: {e}")
        return
    
    # Crear consumer de Kafka
    try:
        consumer = KafkaConsumer(
            KAFKA_TOPIC,
            bootstrap_servers=KAFKA_BOOTSTRAP_SERVERS,
            group_id=CONSUMER_GROUP,
            auto_offset_reset='earliest',
            value_deserializer=lambda x: x
        )
        logger.info(f"Consumer conectado a topic: {KAFKA_TOPIC}")
    except Exception as e:
        logger.error(f"Error conectando a Kafka: {e}")
        return
    
    # Procesar mensajes
    try:
        for message in consumer:
            process_debezium_message(message.value, cursor)
            mysql_conn.commit()
    except KeyboardInterrupt:
        logger.info("Deteniendo consumer...")
    except Exception as e:
        logger.error(f"Error en el consumer: {e}")
    finally:
        consumer.close()
        mysql_conn.close()
        logger.info("Consumer detenido")

if __name__ == "__main__":
    main()