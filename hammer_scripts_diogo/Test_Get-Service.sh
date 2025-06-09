#!/bin/bash

# sc query MariaDB

# mariadb -uroot -proot -e "SET GLOBAL innodb_fast_shutdown = 0;"
# net stop mariadb 
# mv /var/lib/mysql/ib_logfile[01] /tmp
# net start mariadb

# echo "Good"

# FILE="C:/SBD/test.cnf"

# cat >$FILE <<EOF
# [mysqld]
# bind-address = 0.0.0.0
# max_connections = 100
# innodb_buffer_pool_size = 256M
# innodb_log_buffer_size = 8M

# EOF