
set benchmark_tcl $env(BENCHMARK_TCL)
# set run_agent $env(RUN_AGENT)

# metset agent_hostname laptop-cf5747ge
# metset agent_id 17555
# metset agent_id $run_agent
# metset agent_id 17556
# metset laptop-cf5747ge 17556
tcstart
# metstart
# metstatus
source $benchmark_tcl
vudestroy
vucreate
vustatus
vurun
tcstatus
print dict
tcstop
# metstop
exit