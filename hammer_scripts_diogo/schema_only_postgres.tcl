# echo "Creating TPCC schema for PostgreSQL..."

dbset db pg
dbset bm TPC-C

# Connection
diset connection pg_host localhost
diset connection pg_port 5432

# Schema settings
diset tpcc pg_user tpcc
diset tpcc pg_pass tpcc
diset tpcc pg_dbase tpcc
diset tpcc pg_count_ware $env(WH)
diset tpcc pg_partition false
# diset tpcc pg_no_vacuum true

buildschema

# echo "PostgreSQL schema build complete."
