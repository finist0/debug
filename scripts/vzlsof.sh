#!/bin/bash
#
# The script search for files opened on a device major:minor (provided via args).
#
# Usage: vzlsof.sh MAJOR:MINOR
#
# Example: vzlsof.sh $(cat /sys/devices/virtual/block/ploop16075/ploop16075p1/dev)
#

IFS=':'
read major minor <<< "$1"
IFS=$' \t\n'

function extract_major_minor()
{
    device_id="$1"

# https://sites.uclouvain.be/SystInfo/usr/include/sys/sysmacros.h
#
#__extension__ __extern_inline unsigned int
#__NTH (gnu_dev_major (unsigned long long int __dev))
#{
#  return ((__dev >> 8) & 0xfff) | ((unsigned int) (__dev >> 32) & ~0xfff);
#}
#
#__extension__ __extern_inline unsigned int
#__NTH (gnu_dev_minor (unsigned long long int __dev))
#{
#  return (__dev & 0xff) | ((unsigned int) (__dev >> 12) & ~0xff);
#}

    major=$(( ((device_id >> 8) & 0xfff) | ((device_id >> 32) & ~0xfff) ))
    #echo "Calculated Major: $major"

    minor=$(( (device_id & 0xff) | ((device_id >> 12) & ~0xff) ))
    #echo "Calculated Minor: $minor"

    echo "$major:$minor"
}

dev_str="$major:$minor"
echo "Looking for files opened on a device major:minor $major:$minor"
echo "Checking /proc/PID/fd/*, /proc/PID/cwd, /proc/PID/root files"
echo "============================================================"

for pid in $(ls /proc | grep -E '^[0-9]+$'); do
    #echo "Process ID: $pid"

    fd_dir="/proc/$pid/fd"
    if [ ! -d "$fd_dir" ]; then
	continue
    fi

    for fpath in $(find "$fd_dir" -mindepth 1 -maxdepth 1) "/proc/$pid/cwd" "/proc/$pid/root"; do
	#echo "FILE = $fpath"
	device_id=$(stat -L "$fpath" -c "%d")
	#echo "DEVICE_ID: $device_id"
	fd_str=$(extract_major_minor $device_id)
	#echo "FILE DEVICE: $fd_str"
	if [ "x${dev_str}" = "x${fd_str}" ]; then
	    cmdline="$(cat /proc/$pid/cmdline | tr '\0' ' ')"
	    link="$(readlink $fpath)"
	    echo "PID $pid CMDLINE $cmdline FILE $fpath -> $link"
	fi
    done
done
