#!/bin/bash

net stop postgresql-x64-17
if [ $? -ne 0 ]; then
  echo "❌ Failed to stop Postgres service"
  # mysqladmin shutdown
  exit
fi

echo "Postgres Service stopped."