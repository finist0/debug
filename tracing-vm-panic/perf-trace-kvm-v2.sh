#!/bin/bash
#
# Written by Pasha Tikhomirov
#

set -e

DATE=$(date +%F.%H_%M_%S)
echo "Start tracing at $DATE"
DIR="./perf-logs-kvm-$DATE"
mkdir "$DIR"
echo "Created $DIR for perf logs"
cd "$DIR"
echo "(press Ctrl + C to stop, or it will automatically stop on first VM crash)"

set +e

# Erase all old probes, add only those we require now.
perf probe -d probe:*

# syscall sys_migrate_pages() -> kernel_migrate_pages() -> do_migrate_pages()
perf probe -f "kernel_migrate_pages:29 pid=pid comm=task->comm:string"

# cpuset::mems cpuset_migrate_mm() -> cpuset_migrate_mm_workfn() -> do_migrate_pages()
#perf probe -f "cpuset_migrate_mm pid=mm->owner->pid comm=mm->owner->comm:string"
perf probe -f "cpuset_write_resmask:51 buf=buf:string cpucgroup=of->kn->parent->name:string parent_name=of->kn->parent->parent->name:string pparent_name=of->kn->parent->parent->parent->name:string"

# memory::numa_migrate
perf probe -f memcg_numa_migrate_write

# automatic kernel memory migration
# Disabled in kernel config by default, check "kernel.numa_balancing" sysctl.

echo "perf probes were successfully set, starting data recording."

perf record -a -e 'probe:*' --switch-output=15m &
TRACE_PID="$!"

finish_trace () {
        echo "Stop tracing at $(date +%F.%H_%M_%S)"
        if [ -n "$TRACE_PID" ]; then
                kill "$TRACE_PID"
        fi

        pstree -sSpla 1 > pstree.log

        # Erase all old probes, add only those we require now.
	sleep 5
        perf probe -d probe:*
        exit 0
}
trap 'finish_trace' SIGINT

python3 ../detect-vm-panic.py | tee detect-vm-panic.log

finish_trace
