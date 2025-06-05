puts "📆 Creating TPCC schema for Oracle..."
set env(ORACLE_HOME) "/opt/oracle/instantclient_23_7"
set env(LD_LIBRARY_PATH) "/opt/oracle/instantclient_23_7"

dbset db ora
dbset bm TPC-C

# Oracle connection settings
diset connection ora_host host.docker.internal
diset connection ora_port 1521
diset connection ora_service_name FREEPDB1
diset tpcc ora_user tpcc
diset tpcc ora_pass tpcc
diset tpcc ora_two_task NONE

diset tpcc ora_count_ware $env(WH)
diset tpcc ora_partition false

diset tpcc ora_no_logon false
diset tpcc ora_direct_load true

diset tpcc ora_dba_user sys
diset tpcc ora_dba_pass Test123
diset tpcc ora_dba_sid FREEPDB1
diset tpcc ora_dba_conn_type service
diset tpcc ora_dba_os_auth false
diset tpcc ora_instance FREEPDB1

diset tpcc ora_storage_tech heap

buildschema
puts "✅ Schema creation issued for Oracle. Check logs to confirm success."


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
