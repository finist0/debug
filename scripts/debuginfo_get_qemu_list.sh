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

qemu_pkgs=(	"qemu-kvm-common"
		"qemu-kvm-core"
		"qemu-kvm"
		"qemu-kvm-block-rbd"
		"qemu-kvm-block-blkio"
		"qemu-kvm-device-display-virtio-gpu"
		"qemu-kvm-device-display-virtio-gpu-pci"
		"qemu-kvm-device-display-virtio-vga"
		"qemu-kvm-device-usb-host"
		"qemu-kvm-device-usb-redirect"
		"qemu-kvm-tools"
		"qemu-img"	)

for i in "${qemu_pkgs[@]}"; do
	rpm -q "$i" >/dev/null && pkg_list=("${pkg_list[@]}" "$i")
done

pkg_list=("${pkg_list[@]}" "libvirt")
#echo ${pkg_list[@]}

for i in "${pkg_list[@]}"; do
	# keyutils-1.6.3-1.vl9.src.rpm
	srcname=$(rpm -q --queryformat="%{SOURCERPM}" "$i")
	srcname=${srcname%%-[0-9]*}
	echo -en "$srcname "
	rpm -q --queryformat="%{NAME} %{VERSION} %{RELEASE} %{ARCH}\n" "$i"
done

