#!/bin/bash

# HammerDB TCL scripts
SCHEMA_TCL=~/hammer_scripts/schema_only_postgres.tcl
BENCHMARK_TCL=~/hammer_scripts/benchmark_run_postgres.tcl
LOGDIR=~/hammer_scripts/logs_postgres_ALLWAREHOUSES1
RESULTS_CSV="$LOGDIR/results_postgres.csv"
mkdir -p "$LOGDIR"
echo "LOGID,Run,Total Transactions,Transactions Per Minute" > "$RESULTS_CSV"

# SSH settings
HOST_USER=joko
HOST_IP=192.168.1.173

# Config list: VU, WH, MC, SB, WB
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
  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $HOST_USER@$HOST_IP "~/restart_postgres.sh $MC $SB $WB"
  if [ $? -ne 0 ]; then
    echo "❌ Failed to restart PostgreSQL container — skipping config $config"
    continue
  fi

  echo "🏗️ [$LOGID] Building schema"
  WH="$WH" /opt/HammerDB-5.0/hammerdbcli auto "$SCHEMA_TCL"

  echo "📋 [$LOGID] Saving configuration dict and enabling metrics"
  VU="$VU" WH="$WH" DBNAME="$DBNAME" ALLWAREHOUSES=1 \
  /opt/HammerDB-5.0/hammerdbcli <<EOF > "$LOGDIR/${LOGID}_dict.txt"
puts "📋 Running dict export for $LOGID"
source "$BENCHMARK_TCL"
metset localhost
metstart
metstatus
print dict
exit
EOF

  for run in $(seq 1 $REPEATS); do
    echo "🚀 [$LOGID] Benchmark Run $run"
    LOGFILE="$LOGDIR/${LOGID}_run${run}.log"

    VU="$VU" WH="$WH" DBNAME="$DBNAME" ALLWAREHOUSES=1 \
    /opt/HammerDB-5.0/hammerdbcli <<EOF > "$LOGFILE"
puts "🚀 Starting benchmark run $run for $LOGID"
source "$BENCHMARK_TCL"
metstatus
tcstart
vudestroy
vucreate
vustatus
vurun
tcstatus
tcstop
metstop
exit
EOF

    # 🔍 Parse and log results to CSV
    TOTAL_TX=$(grep "Total Transactions" "$LOGFILE" | awk -F: '{print $2}' | tr -d ' ')
    TPM=$(grep "Transactions Per Minute" "$LOGFILE" | awk -F: '{print $2}' | tr -d ' ')
    echo "$LOGID,$run,$TOTAL_TX,$TPM" >> "$RESULTS_CSV"
  done

  echo "✅ [$LOGID] All $REPEATS runs complete"
done

echo "🏁 All PostgreSQL benchmarks finished."
