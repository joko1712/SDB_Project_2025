puts "Running TPCC benchmark for PostgreSQL..."

dbset db pg
dbset bm TPC-C

# Connection
diset connection pg_host localhost
diset connection pg_port 5432

# Benchmark settings
diset tpcc pg_user tpcc
diset tpcc pg_pass tpcc
diset tpcc pg_dbase tpcc
diset tpcc pg_count_ware $env(WH)
diset tpcc pg_driver timed
diset tpcc pg_rampup 2
diset tpcc pg_duration 3
diset tpcc pg_async_client 10
# Test true and false
diset tpcc pg_allwarehouse false

tcstart
vuset vu $env(VU)
loadscript
vucreate
vurun
vudestroy
print dict
tcstatus
tcstop

puts "PostgreSQL benchmark run complete."
