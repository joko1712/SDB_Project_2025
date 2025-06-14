#!/bin/bash

DOCKER="/usr/local/bin/docker"

MAX_CONNECTIONS=$1
SHARED_BUFFERS=$2
WAL_BUFFERS=$3

echo "🛑 Stopping and removing old PostgreSQL container..."
$DOCKER stop postgres-bench >/dev/null 2>&1
$DOCKER rm postgres-bench >/dev/null 2>&1

echo "🚀 Starting PostgreSQL with:"
echo "    max_connections=$MAX_CONNECTIONS"
echo "    shared_buffers=$SHARED_BUFFERS"
echo "    wal_buffers=$WAL_BUFFERS"

$DOCKER run -d --name postgres-bench \
  -v /Users/joko/pg_config/pg_hba.conf:/etc/postgresql/pg_hba.conf \
  -e POSTGRES_PASSWORD=root \
  -e POSTGRES_DB=tpcc \
  -p 5432:5432 \
  postgres:16 \
  -c max_connections=$MAX_CONNECTIONS \
  -c shared_buffers=$SHARED_BUFFERS \
  -c wal_buffers=$WAL_BUFFERS \
  -c hba_file=/etc/postgresql/pg_hba.conf

# Wait until DB is ready (max 30 seconds)
echo "⏳ Waiting for PostgreSQL to be ready..."
for i in {1..30}; do
  if $DOCKER exec postgres-bench pg_isready -U postgres &>/dev/null; then
    echo "✅ PostgreSQL is ready."
    break
  fi
  sleep 1
done

if [ $i -eq 30 ]; then
  echo "❌ PostgreSQL did not become ready in time. Here's the container log:"
  $DOCKER logs postgres-bench
  exit 1
fi

# ✅ Set a password for 'postgres' to avoid HammerDB fallback failure
$DOCKER exec -u postgres postgres-bench psql -c "ALTER USER postgres WITH PASSWORD 'root';"

# ✅ Ensure the 'tpcc' user exists
$DOCKER exec -u postgres postgres-bench psql -c "DO \$\$ BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'tpcc') THEN
    CREATE USER tpcc WITH PASSWORD 'root';
  END IF;
END \$\$;"

# ✅ Make tpcc the owner of the tpcc database
$DOCKER exec -u postgres postgres-bench psql -c "ALTER DATABASE tpcc OWNER TO tpcc;"

# ✅ Grant privileges to tpcc just in case
$DOCKER exec -u postgres postgres-bench psql -c "GRANT ALL PRIVILEGES ON DATABASE tpcc TO tpcc;"

echo "✅ PostgreSQL user 'tpcc' is set up and owns database 'tpcc'"
