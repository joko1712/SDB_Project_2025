puts "📦 Creating TPCC schema for MariaDB..."

dbset db maria
dbset bm TPC-C

# Connection settings
diset connection maria_host host.docker.internal
diset connection maria_port 3306

# Schema settings
diset tpcc maria_user root

diset tpcc maria_pass root
set dbname $env(DBNAME)
diset tpcc maria_dbase $dbname

diset tpcc maria_count_ware 10
diset tpcc maria_storage_engine innodb
diset tpcc maria_partition false
diset tpcc maria_no_stored_procs false

buildschema

puts "✅ Schema build issued — check for success."
# quit ;# remove to avoid HammerDB v5.0 bug
