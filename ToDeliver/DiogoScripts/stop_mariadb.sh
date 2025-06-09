#!/bin/bash

mariadb -uroot -proot -e "SET GLOBAL innodb_fast_shutdown = 0;"
net stop mariadb

while sc query "mariadb" |grep -qo STOP_PENDING; do
    sleep 1
done

echo "MariaDB Service stopped."
