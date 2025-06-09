
set benchmark_tcl $env(BENCHMARK_TCL)

# metset agent_hostname laptop-cf5747ge
# metset agent_id 17555
# metset agent_id 27468
# metset laptop-cf5747ge 17556
tcstart
# metstart
# metstatus
source $benchmark_tcl
print dict
tcstop
# metstop
exit