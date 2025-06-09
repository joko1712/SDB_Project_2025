#!/bin/bash

MAX_CONNECTIONS=$1
SHARED_BUFFERS=$2
WAL_BUFFERS=$3

echo "MAX_CONNECTIONS: [$MAX_CONNECTIONS]"
echo "SHARED_BUFFERS: [$SHARED_BUFFERS]"
echo "WAL_BUFFERS: [$WAL_BUFFERS]"

echo "None" > ./tmp/server-postgres-log.txt &
sleep 1
while ! grep -m1 "None" < ./tmp/server-postgres-log.txt; do
    sleep 1
done

echo "🛑 Stopping and removing old PostgreSQL container..."

export PGPASSWORD='postgres';
psql -h localhost -U postgres -c "ALTER SYSTEM SET max_connections TO $MAX_CONNECTIONS;"
psql -h localhost -U postgres -c "ALTER SYSTEM SET shared_buffers TO '$SHARED_BUFFERS';"
psql -h localhost -U postgres -c "ALTER SYSTEM SET wal_buffers TO '$WAL_BUFFERS';"

./stop_postgres.sh > ./tmp/server-postgres-log.txt &
sleep 1
while ! grep -m1 "Postgres Service stopped." < ./tmp/server-postgres-log.txt; do
    sleep 1
done

echo "🚀 Starting PostgreSQL with:"
echo "    max_connections=$MAX_CONNECTIONS"
echo "    shared_buffers=$SHARED_BUFFERS"
echo "    wal_buffers=$WAL_BUFFERS"

# Wait until DB is ready
echo "⏳ Waiting for PostgreSQL to be ready..."
./start_postgres.sh > /tmp/server-log.txt &
sleep 1
while ! grep -m1 "Postgres Service started." < /tmp/server-log.txt; do
    sleep 1
done

echo "✅ PostgreSQL is ready."
