#!/bin/bash

echo "🧪 PROBANDO PIPELINE DEBEZIUM - MYSQL A MYSQL"
echo "=============================================="

# Función para verificar si un comando MySQL funcionó
check_mysql_cmd() {
    if [ $? -eq 0 ]; then
        echo "✅ $1"
    else
        echo "❌ Error en: $1"
        exit 1
    fi
}

echo -e "\n1️⃣ INSERTANDO REGISTRO DE PRUEBA EN zalvadora_local_2.users..."
mysql -uroot -p -e "INSERT INTO zalvadora_local_2.users (firstname, lastname, email, status) VALUES ('TestUser', 'Pipeline', 'test@pipeline.com', 'active');" 2>/dev/null
check_mysql_cmd "Insert en zalvadora_local_2"

echo -e "\n⏳ Esperando 5 segundos para propagación..."
sleep 5

echo -e "\n🔍 VERIFICANDO EN jdbc_copia.users..."
RESULT=$(mysql -uroot -p -se "SELECT COUNT(*) FROM jdbc_copia.users WHERE email = 'test@pipeline.com';" 2>/dev/null)
if [ "$RESULT" -gt "0" ]; then
    echo "✅ INSERT replicado correctamente - Registros encontrados: $RESULT"
else
    echo "❌ INSERT no se replicó"
fi

echo -e "\n2️⃣ ACTUALIZANDO REGISTRO DE PRUEBA..."
mysql -uroot -p -e "UPDATE zalvadora_local_2.users SET status = 'updated' WHERE email = 'test@pipeline.com';" 2>/dev/null
check_mysql_cmd "Update en zalvadora_local_2"

echo -e "\n⏳ Esperando 5 segundos para propagación..."
sleep 5

echo -e "\n🔍 VERIFICANDO UPDATE EN jdbc_copia.users..."
RESULT=$(mysql -uroot -p -se "SELECT COUNT(*) FROM jdbc_copia.users WHERE email = 'test@pipeline.com' AND status = 'updated';" 2>/dev/null)
if [ "$RESULT" -gt "0" ]; then
    echo "✅ UPDATE replicado correctamente - Registros actualizados: $RESULT"
else
    echo "❌ UPDATE no se replicó"
fi

echo -e "\n3️⃣ ELIMINANDO REGISTRO DE PRUEBA..."
mysql -uroot -p -e "DELETE FROM zalvadora_local_2.users WHERE email = 'test@pipeline.com';" 2>/dev/null
check_mysql_cmd "Delete en zalvadora_local_2"

echo -e "\n⏳ Esperando 5 segundos para propagación..."
sleep 5

echo -e "\n🔍 VERIFICANDO DELETE EN jdbc_copia.users..."
RESULT=$(mysql -uroot -p -se "SELECT COUNT(*) FROM jdbc_copia.users WHERE email = 'test@pipeline.com';" 2>/dev/null)
if [ "$RESULT" -eq "0" ]; then
    echo "✅ DELETE replicado correctamente - Registro eliminado"
else
    echo "❌ DELETE no se replicó - Registros restantes: $RESULT"
fi

echo -e "\n🎉 PRUEBA COMPLETADA"
echo "Revisa los resultados arriba para verificar que la replicación funcione correctamente."