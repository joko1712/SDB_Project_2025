puts "🚀 Starting TPCC benchmark..."

# Connection settings again (redundant but safe)
dbset db ora
diset connection ora_host host.docker.internal
diset connection ora_port 1521
diset connection ora_service_name FREEPDB1

# Benchmark run settings
diset tpcc ora_user tpcc
diset tpcc ora_pass tpcc

set dbname $env(DBNAME)
set warehouses $env(WH)
set vus $env(VU)

diset tpcc ora_dbase $dbname
diset tpcc ora_count_ware $warehouses

diset tpcc ora_driver timed
diset tpcc ora_rampup 2
diset tpcc ora_duration 3
diset tpcc ora_async_client 10

# Run with specified virtual users
vuset vu $vus
loadscript
vucreate
vurun
vudestroy

puts "✅ Benchmark run complete."
