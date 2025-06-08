#!/bin/bash

DOCKER="/usr/local/bin/docker"  # Adjust if needed
SGA_TARGET=$1
PGA_AGGREGATE_TARGET=$2
PROCESSES=$3

CONTAINER_NAME="oracle-bench"

echo "🔝 Stopping and removing old Oracle container..."
$DOCKER stop $CONTAINER_NAME >/dev/null 2>&1
$DOCKER rm $CONTAINER_NAME >/dev/null 2>&1

echo "🚀 Starting Oracle with:"
echo "    sga_target=$SGA_TARGET"
echo "    pga_aggregate_target=$PGA_AGGREGATE_TARGET"
echo "    processes=$PROCESSES"

$DOCKER run -d \
  --name $CONTAINER_NAME \
  -p 1521:1521 \
  -e ORACLE_PWD=Test123 \
  -e ORACLE_SGA_TARGET=$SGA_TARGET \
  -e ORACLE_PGA_AGGREGATE_TARGET=$PGA_AGGREGATE_TARGET \
  -e ORACLE_PROCESSES=$PROCESSES \
  container-registry.oracle.com/database/free:latest



sga_target=$SGA_TARGET,pga_aggregate_target=$PGA_AGGREGATE_TARGET,processes=$PROCESSES

# Wait for Oracle to be ready (max 90s)
echo "⏳ Waiting for Oracle DB to become ready..."
for i in {1..90}; do
  READY=$($DOCKER logs $CONTAINER_NAME 2>&1 | grep -c "DATABASE IS READY TO USE")
  if [ "$READY" -gt 0 ]; then
    echo "✅ Oracle is ready."
    break
  fi
  sleep 1
done

if [ "$READY" -eq 0 ]; then
  echo "❌ Oracle did not become ready in time. Here's the log:"
  $DOCKER logs $CONTAINER_NAME | tail -n 50
  exit 1
fi

# Create tpcc user and grant privileges
$DOCKER exec -i $CONTAINER_NAME bash -c 'source /opt/oracle/env.sh && sqlplus -s sys/Test123@localhost:1521/FREEPDB1 as sysdba' <<EOF
WHENEVER SQLERROR EXIT SQL.SQLCODE
CREATE USER tpcc IDENTIFIED BY tpcc;
GRANT CONNECT, RESOURCE, DBA TO tpcc;
EXIT;
EOF

echo "✅ Oracle user 'tpcc' is set up with DBA privileges."

