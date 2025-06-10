#!/usr/bin/env python3
"""
Procesador que lee mensajes existentes de Kafka y los replica en MySQL
"""

import json
import subprocess
import mysql.connector
import logging

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

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

def get_kafka_messages():
    """Obtener mensajes de Kafka usando docker exec"""
    cmd = [
        'docker', 'exec', 'debezium-kafka-1',
        'kafka-console-consumer',
        '--bootstrap-server', 'localhost:9092',
        '--topic', 'Analyticdb1.zalvadora_local_2.users',
        '--from-beginning',
        '--timeout-ms', '30000'
    ]
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=35)
        if result.stdout:
            return result.stdout.strip().split('\n')
        return []
    except subprocess.TimeoutExpired:
        logger.info("Timeout obteniendo mensajes - normal si no hay mensajes nuevos")
        return []
    except Exception as e:
        logger.error(f"Error obteniendo mensajes: {e}")
        return []

def process_message(message_line, cursor):
    """Procesar una línea de mensaje de Kafka"""
    try:
        if not message_line.strip() or 'Processed a total of' in message_line:
            return
            
        data = json.loads(message_line)
        
        # Buscar el payload
        if 'payload' not in data:
            return
            
        payload = data['payload']
        operation = payload.get('op')
        
        if operation in ['c', 'r', 'u']:  # CREATE, READ (snapshot), o UPDATE
            after_data = payload.get('after', {})
            if after_data and after_data.get('id') and after_data.get('email'):
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
                op_type = "INSERT" if operation == 'c' else "UPDATE" if operation == 'u' else "SNAPSHOT"
                logger.info(f"{op_type}: id={after_data.get('id')}, email={after_data.get('email')}")
                
        elif operation == 'd':  # DELETE
            before_data = payload.get('before', {})
            if before_data and before_data.get('id'):
                delete_sql = "DELETE FROM users WHERE id = %(id)s"
                cursor.execute(delete_sql, {'id': before_data.get('id')})
                logger.info(f"DELETE: id={before_data.get('id')}")
                
    except json.JSONDecodeError:
        logger.debug(f"Línea no es JSON válido: {message_line[:100]}...")
    except Exception as e:
        logger.error(f"Error procesando mensaje: {e}")

def main():
    logger.info("Procesando mensajes existentes de Kafka...")
    
    # Conectar a MySQL
    try:
        mysql_conn = mysql.connector.connect(**MYSQL_CONFIG)
        cursor = mysql_conn.cursor()
        create_table_if_not_exists(cursor)
        logger.info("Conectado a MySQL")
    except Exception as e:
        logger.error(f"Error conectando a MySQL: {e}")
        return
    
    # Obtener y procesar mensajes
    messages = get_kafka_messages()
    logger.info(f"Obtenidos {len(messages)} mensajes de Kafka")
    
    processed = 0
    for message in messages:
        process_message(message, cursor)
        processed += 1
    
    mysql_conn.commit()
    mysql_conn.close()
    
    logger.info(f"Procesamiento completado. {processed} mensajes procesados.")

if __name__ == "__main__":
    main()