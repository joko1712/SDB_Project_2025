#!/bin/bash

mariadb -uroot -proot -e "SET GLOBAL innodb_fast_shutdown = 0;"
net stop mariadb
# if [ $? -ne 0 ]; then
  # echo "❌ Failed to stop MariaDB service — killing the service"
  # mysqladmin -uroot -proot shutdown
# fi

# for i in {1..60}; do
  # if sc query "mariadb" |grep -qo STOP_PENDING; then
    # echo "MariaDB Service stopped."
    # break
  # fi
  # # sleep 1
# done

while sc query "mariadb" |grep -qo STOP_PENDING; do
    sleep 1
done

# for i in {1..60}; do
  # if sc query "mariadb" |grep -qo STOP_PENDING; then
    # echo "MariaDB Service stopped."
    # break
  # fi
  # # sleep 1
# done

echo "MariaDB Service stopped."

# sc query "mariadb" |grep -qo STOP_PENDING && echo "mariadb not stopped!" || echo "mariadb has stopped running"
# sc query "mariadb" |grep -qo STOPPED && echo "mariadb stopped!" || echo "mariadb has stopped running"