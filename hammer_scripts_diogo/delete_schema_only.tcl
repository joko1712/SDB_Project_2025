puts "Deleting TPCC schemas for MariaDB..."

dbset db maria
dbset bm TPC-C

# Connection settings
diset connection maria_host 127.0.0.1
diset connection maria_port 3306

# Schema settings
diset tpcc maria_user root

diset tpcc maria_pass root
set dbname $env(DBNAME)
diset tpcc maria_dbase $dbname

deleteschema

puts "deleteschema issued — check for success."
