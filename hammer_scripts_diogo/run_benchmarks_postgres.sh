#!/bin/bash

set -E

trap 'ERRO_LINENO=$LINENO' ERR
trap '_failure' EXIT

_failure() {
  ERR_CODE=$? # capture last command exit code
  set +xv # turns off debug logging, just in case
  if [[  $- =~ e && ${ERR_CODE} != 0 ]]
  then
      # only log stack trace if requested (set -e)
      # and last command failed
      echo
      echo "========= CATASTROPHIC COMMAND FAIL ========="
      echo
      echo "SCRIPT EXITED ON ERROR CODE: ${ERR_CODE}"
      echo
      LEN=${#BASH_LINENO[@]}
      for (( INDEX=0; INDEX<$LEN-1; INDEX++ ))
      do
          echo '---'
          echo "FILE: $(basename ${BASH_SOURCE[${INDEX}+1]})"
          echo "  FUNCTION: ${FUNCNAME[${INDEX}+1]}"
          if [[ ${INDEX} > 0 ]]
          then
           # commands in stack trace
              echo "  COMMAND: ${FUNCNAME[${INDEX}]}"
              echo "  LINE: ${BASH_LINENO[${INDEX}]}"
          else
              # command that failed
              echo "  COMMAND: ${BASH_COMMAND}"
              echo "  LINE: ${ERRO_LINENO}"
          fi
      done
      echo
      echo "======= END CATASTROPHIC COMMAND FAIL ======="
      echo
  fi
}


# HammerDB TCL scripts
SCHEMA_TCL=~/hammer_scripts/schema_only_postgres.tcl
BENCHMARK_TCL=~/hammer_scripts/benchmark_run_postgres.tcl
LOGDIR=~/hammer_scripts/logs_postgres
mkdir -p "$LOGDIR"

# Your SSH info for the host machine
HOST_USER=root
HOST_IP=127.0.0.1

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

  set -v -x -e

  echo "🔧 [$LOGID] Restarting PostgreSQL container on host..."
  # ssh $HOST_USER@$HOST_IP "~/restart_postgres.sh $MC $SB $WB"
  C:/SBD/restart_postgres.sh ${MC} ${BP} ${LB}
  if [ $? -ne 0 ]; then
    echo "❌ Failed to restart PostgreSQL container — skipping config $config"
    continue
  fi
 
  set +v +x +e
  
# set -v -x -e

  # echo "🔧 [$DBNAME] Restarting MariaDB on host with MC=$MC, BP=$BP, LB=$LB"
  # # ssh $HOST_USER@$HOST_IP
  # # MC="$MC" BP="$BP" LB="$LB" DBNAME="$DBNAME" "C:/SBD/restart_mariadb.sh"
  # # "C:/SBD/restart_mariadb.sh \"${MC}\" \"${BP}\" \"${LB}\" \"${DBNAME}\""
  # C:/SBD/restart_mariadb.sh ${MC} ${BP} ${LB} ${DBNAME}
  # if [ $? -ne 0 ]; then
    # echo "❌ Failed to restart MariaDB container — skipping config $config"
    # continue
  # fi
  
  # # Get-Service -ComputerName computername -Name servicename | Stop-Service -Force

# set +v +x +e

  echo "📦 [$LOGID] Building schema"
  WH="$WH" "C:/Program Files/HammerDB-5.0/hammerdbcli" auto "$SCHEMA_TCL"
  
  for run in $(seq 1 $REPEATS); do
    echo "🚀 [$LOGID] Benchmark Run #$run"
    VU="$VU" WH="$WH" DBNAME="$DBNAME" ALLWAREHOUSES=1 "C:/Program Files/HammerDB-5.0/hammerdbcli" auto "$BENCHMARK_TCL" \
      > "$LOGDIR/${LOGID}_run${run}.log"
  done

  echo "✅ [$LOGID] All $REPEATS runs complete"
done

echo "🏁 All PostgreSQL benchmarks finished."
