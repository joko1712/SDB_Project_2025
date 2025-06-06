
set benchmark_tcl $env(BENCHMARK_TCL)

metset agent_hostname laptop-cf5747ge
metset agent_id 17556
# metset laptop-cf5747ge 17556
metstart
metstatus
source $benchmark_tcl
print dict
metstop
exit