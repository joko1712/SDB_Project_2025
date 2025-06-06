#!/bin/bash

# HammerDB TCL scripts
SCHEMA_TCL=~/hammer_scripts/schema_only_postgres.tcl
BENCHMARK_TCL=~/hammer_scripts/benchmark_run_postgres.tcl
LOGDIR=~/hammer_scripts/logs_postgres
mkdir -p "$LOGDIR"

# SSH settings to connect to host Mac (update if needed)
HOST_USER=joko
HOST_IP=192.168.1.173

# Config list: each entry is "VU,WH,MC,SB,WB"
# VU = Virtual Users, WH = Warehouses
# MC = max_connections, SB = shared_buffers, WB = wal_buffers
CONFIGS=(
  "5,5,100,256MB,8MB"
  "10,10,200,512MB,16MB"
  "20,20,500,1GB,32MB"
  "50,20,500,2GB,64MB"
  "20,5,200,256MB,8MB"
  "10,10,200,2GB,64MB"
  "5,20,100,128MB,8MB"
  "100,50,1000,4GB,128MB"
)

REPEATS=5

for config in "${CONFIGS[@]}"; do
  IFS=',' read -r VU WH MC SB WB <<< "$config"
  DBNAME="tpcc"
  LOGID="pg_vu${VU}_wh${WH}_mc${MC}_sb${SB}_wb${WB//MB/}"

  echo "🔧 [$LOGID] Restarting PostgreSQL container on host..."
  ssh $HOST_USER@$HOST_IP "~/restart_postgres.sh $MC $SB $WB"
  if [ $? -ne 0 ]; then
    echo "❌ Failed to restart PostgreSQL container — skipping config $config"
    continue
  fi

  echo "📦 [$LOGID] Building schema"
  WH="$WH" /opt/HammerDB-5.0/hammerdbcli auto "$SCHEMA_TCL"

  for run in $(seq 1 $REPEATS); do
    echo "🚀 [$LOGID] Benchmark Run $run"
    VU="$VU" WH="$WH" /opt/HammerDB-5.0/hammerdbcli auto "$BENCHMARK_TCL" \
      > "$LOGDIR/${LOGID}_run${run}.log"
  done

  echo "✅ [$LOGID] All $REPEATS runs complete"
done

echo "🏁 All PostgreSQL benchmarks finished."
