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

# Your SSH info for the host machine
HOST_USER=root
HOST_IP=127.0.0.1

# Files
DELETE_SCHEMA=C:/SBD/delete_schema_only.tcl

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

echo "DELETE_SCHEMA: [$DELETE_SCHEMA]"

for config in "${CONFIGS[@]}"; do
  IFS=',' read -r VU WH MC BP LB <<< "$config"
  DBNAME="tpcc_vu${VU}_wh${WH}_mc${MC}_bp${BP}_lb${LB//M/}"  # sanitize for filenames
  CONTAINER_NAME="mariadb-bench"
  
  set -v -x -e

  echo "🔧 [$DBNAME] Restarting MariaDB on host with MC=$MC, BP=$BP, LB=$LB"
  DBNAME="$DBNAME" "C:/Program Files/HammerDB-5.0/hammerdbcli" auto "$DELETE_SCHEMA"
  if [ $? -ne 0 ]; then
    echo "❌ Failed to delete MariaDB container — skipping config $config"
    continue
  fi
  
  set +v +x +e
done

echo "🏁 All benchmarks complete."