#!/bin/bash

# Your SSH info for the host machine
HOST_USER=joko
HOST_IP=192.168.1.173

# Files
SCHEMA_TCL=~/hammer_scripts/schema_only.tcl
BENCHMARK_TCL=~/hammer_scripts/benchmark_run.tcl
LOGDIR=~/hammer_scripts/logs_ALLWAREHOUSES1
mkdir -p "$LOGDIR"

# Config list: each entry is "VU,WH,MC,BP,LB"
CONFIGS=(
  "5,5,100,256M,8M"
  "10,10,200,512M,16M"
  "20,20,500,1G,32M"
  "50,20,500,2G,64M"
  "20,5,200,256M,8M"
  "10,10,200,2G,64M"
  "5,20,100,128M,8M"
  "100,50,1000,4G,128M"
)

REPEATS=5

for config in "${CONFIGS[@]}"; do
  IFS=',' read -r VU WH MC BP LB <<< "$config"
  DBNAME="tpcc_vu${VU}_wh${WH}_mc${MC}_bp${BP}_lb${LB//M/}" 
  CONTAINER_NAME="mariadb-bench"

  echo "🔧 [$DBNAME] Restarting MariaDB on host with MC=$MC, BP=$BP, LB=$LB"
  ssh $HOST_USER@$HOST_IP "~/restart_mariadb.sh $MC $BP $LB"
  if [ $? -ne 0 ]; then
    echo "❌ Failed to restart MariaDB container — skipping config $config"
    continue
  fi

  echo "📦 [$DBNAME] Creating DB"
  mysql -h host.docker.internal -P 3306 -u root -proot -e "DROP DATABASE IF EXISTS $DBNAME; CREATE DATABASE $DBNAME;"

  echo "🏗️ [$DBNAME] Building schema"
  DBNAME="$DBNAME" /opt/HammerDB-5.0/hammerdbcli auto "$SCHEMA_TCL"

  echo "📋 [$DBNAME] Saving configuration dict and enabling metrics"
  VU="$VU" WH="$WH" DBNAME="$DBNAME" ALLWAREHOUSES=1 \
  /opt/HammerDB-5.0/hammerdbcli <<EOF > "$LOGDIR/${DBNAME}_dict.txt"
puts "📋 Running dict export for $DBNAME"
source "$BENCHMARK_TCL"
metset localhost
metstart
metstatus
print dict
exit
EOF

    for run in $(seq 1 $REPEATS); do
    echo "🚀 [$DBNAME] Benchmark Run #$run"

    LOGFILE="$LOGDIR/${DBNAME}_run${run}.log"

    VU="$VU" WH="$WH" DBNAME="$DBNAME" ALLWAREHOUSES=1 /opt/HammerDB-5.0/hammerdbcli <<EOF > "$LOGFILE"
puts "🚀 Starting benchmark run $run for $DBNAME"
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

    # 🔍 Parse transaction results
    TOTAL_TX=$(grep "Total Transactions" "$LOGFILE" | awk -F: '{print $2}' | tr -d ' ')
    TPM=$(grep "Transactions Per Minute" "$LOGFILE" | awk -F: '{print $2}' | tr -d ' ')
    echo "$DBNAME,$run,$TOTAL_TX,$TPM" >> "$RESULTS_CSV"
  done

  echo "✅ [$DBNAME] Finished all $REPEATS runs"
done

echo "🏁 All benchmarks complete."
