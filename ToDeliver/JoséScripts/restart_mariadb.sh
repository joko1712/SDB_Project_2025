#!/bin/bash

DOCKER="/usr/local/bin/docker"

MAX_CONNECTIONS=$1
BUFFER_POOL_SIZE=$2
LOG_BUFFER_SIZE=$3

echo "🛑 Stopping old MariaDB container..."
$DOCKER stop mariadb-bench >/dev/null 2>&1
$DOCKER rm mariadb-bench >/dev/null 2>&1

echo "🚀 Starting MariaDB with:"
echo "    max_connections=$MAX_CONNECTIONS"
echo "    innodb_buffer_pool_size=$BUFFER_POOL_SIZE"
echo "    innodb_log_buffer_size=$LOG_BUFFER_SIZE"

$DOCKER run -d --name mariadb-bench \
  -v $(pwd)/my.cnf:/etc/mysql/conf.d/my.cnf \
  -e MYSQL_ROOT_PASSWORD=root \
  -e MYSQL_DATABASE=tpcc \
  -p 3306:3306 \
  mariadb:latest \
  --max_connections=$MAX_CONNECTIONS \
  --innodb_buffer_pool_size=$BUFFER_POOL_SIZE \
  --innodb_log_buffer_size=$LOG_BUFFER_SIZE


# Wait until DB is ready
until $DOCKER exec mariadb-bench mariadb -u root -proot -e "SELECT 1" &>/dev/null; do
  sleep 1
done

echo "✅ MariaDB container ready."

