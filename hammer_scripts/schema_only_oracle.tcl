\puts "📆 Creating TPCC schema for Oracle..."

dbset db ora
dbset bm TPC-C

# Oracle connection settings
diset connection ora_host host.docker.internal
diset connection ora_port 1521
diset connection ora_service_name FREEPDB1
diset tpcc ora_user tpcc
diset tpcc ora_pass tpcc
diset tpcc ora_two_task NONE

diset tpcc ora_count_ware 5
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

