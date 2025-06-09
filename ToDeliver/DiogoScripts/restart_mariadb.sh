#!/bin/bash

MAX_CONNECTIONS=$1
BUFFER_POOL_SIZE=$2
LOG_BUFFER_SIZE=$3
DATABASE_NAME=$4

echo "None" > ./tmp/server-log.txt &
sleep 1
while ! grep -m1 "None" < ./tmp/server-log.txt; do
    sleep 1
done

echo "🛑 Stopping old MariaDB container..."
./stop_mariadb.sh > ./tmp/server-log.txt &
sleep 1
while ! grep -m1 "MariaDB Service stopped." < ./tmp/server-log.txt; do
    sleep 1
done

cp "C:/Program Files/MariaDB 11.7/data/ib_logfile0" "D:/Diogo - Universidade/Disciplinas/2024 - 2025/2º Semestre/SBD/Projeto/Logfiles/$DATABASE_NAME"

echo "Continue"

cat >"C:/Program Files/MariaDB 11.7/data/my.ini" <<EOF
[mysqld]
datadir=C:/Program Files/MariaDB 11.7/data
port=3306
max_connections = $MAX_CONNECTIONS
innodb_buffer_pool_size = $BUFFER_POOL_SIZE
innodb_log_buffer_size = $LOG_BUFFER_SIZE
[client]
port=3306
plugin-dir=C:\Program Files\MariaDB 11.7/lib/plugin

EOF

wait -n

echo "🚀 Starting MariaDB with:"
echo "    max_connections=$MAX_CONNECTIONS"
echo "    innodb_buffer_pool_size=$BUFFER_POOL_SIZE"
echo "    innodb_log_buffer_size=$LOG_BUFFER_SIZE"

./start_mariadb.sh > /tmp/server-log.txt &
sleep 1
while ! grep -m1 "MariaDB Service started." < /tmp/server-log.txt; do
    sleep 1
done

echo "✅ MariaDB container ready."
