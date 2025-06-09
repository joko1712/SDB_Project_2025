#!/bin/bash

net stop postgresql-x64-17

while sc query postgresql-x64-17 |grep -qo STOP_PENDING; do
    sleep 1
done

echo "Postgres Service stopped."