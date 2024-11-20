#!/bin/bash
#
# The script prepares a list of packages which debuginfo is required to
# debug qemu issues.
#
# The script is to be executed on the target node (where qemu is planned
# to be debugged).
# 
# The list is generated in the format:
#	SOURCERPM NAME VERSION RELEASE ARCH
#
# Usage: debuginfo_get_qemu_list.sh > packages.list
#

pkg_list=($(ldd /usr/libexec/qemu-kvm | awk '$3~/\//{print $3}' | xargs rpm -qf | sort -u))
pkg_list2=($(rpm -q qemu-kvm libvirt))

pkg_list=("${pkg_list[@]}" "${pkg_list2[@]}")
#echo ${pkg_list[@]}

for i in "${pkg_list[@]}"; do
	# keyutils-1.6.3-1.vl9.src.rpm
	srcname=$(rpm -q --queryformat="%{SOURCERPM}" "$i")
	srcname=${srcname%%-[0-9]*}
	echo -en "$srcname "
	rpm -q --queryformat="%{NAME} %{VERSION} %{RELEASE} %{ARCH}\n" "$i"
done

