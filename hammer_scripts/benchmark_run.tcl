puts "🚀 Starting TPCC benchmark..."

# Connection settings again (redundant but safe)
dbset db maria
diset connection maria_host host.docker.internal
diset connection maria_port 3306

# Benchmark run settings
diset tpcc maria_user root
diset tpcc maria_pass root
set dbname $env(DBNAME)
set warehouses $env(WH)
set vus $env(VU)

diset tpcc maria_dbase $dbname
diset tpcc maria_count_ware $warehouses

diset tpcc maria_driver timed
diset tpcc maria_rampup 2
diset tpcc maria_duration 3
diset tpcc maria_async_client 10

# Run with 10 virtual users
vuset vu $vus
loadscript
vucreate
vurun
vudestroy

puts "✅ Benchmark run complete."
