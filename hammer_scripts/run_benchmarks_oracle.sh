#!/bin/bash

# SSH details
HOST_USER=joko
HOST_IP=192.168.1.173

# File path for unified TCL
COMBINED_TCL=~/hammer_scripts/schema_and_benchmark_oracle.tcl
LOGDIR=~/hammer_scripts/logs
mkdir -p "$LOGDIR"

# Config list: each entry is "VU,WH,SGA,PGA,PROC"
CONFIGS=(
  "5,5,512M,256M,100"
  "10,10,1G,512M,200"
  "20,20,2G,1G,300"
  "50,20,4G,2G,500"
  "20,5,1G,512M,200"
  "10,10,2G,1G,200"
  "5,20,512M,256M,100"
  "100,50,8G,4G,1000"
)

REPEATS=5

for config in "${CONFIGS[@]}"; do
  IFS=',' read -r VU WH SGA PGA PROC <<< "$config"
  DBNAME="tpcc_vu${VU}_wh${WH}_sga${SGA}_pga${PGA}_proc${PROC}"

  echo "🔧 [$DBNAME] Restarting Oracle on host with SGA=$SGA, PGA=$PGA, PROC=$PROC"
  ssh $HOST_USER@$HOST_IP "~/restart_oracle.sh $SGA $PGA $PROC"
  if [ $? -ne 0 ]; then
    echo "❌ Failed to restart Oracle container — skipping config $config"
    continue
  fi

  for run in $(seq 1 $REPEATS); do
    echo "🚀 [$DBNAME] Run #$run"
    DBNAME="$DBNAME" VU="$VU" WH="$WH" /opt/HammerDB-5.0/hammerdbcli auto "$COMBINED_TCL" \
      > "$LOGDIR/${DBNAME}_run${run}.log"
  done

  echo "✅ [$DBNAME] Finished all $REPEATS runs"
done

echo "🏁 All Oracle benchmarks complete."
