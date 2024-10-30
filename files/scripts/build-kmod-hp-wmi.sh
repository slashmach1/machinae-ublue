#!/bin/sh

set -oeux pipefail

ARCH="$(rpm -E '%_arch')"
KERNEL="$(rpm -q "${KERNEL_NAME}" --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}')"
RELEASE="$(rpm -E '%fedora')"
cp /tmp/ublue-os-akmods-addons/rpmbuild/SOURCES/_copr_ublue-os-akmods.repo /etc/yum.repos.d/
dnf install -y \
     *hp-wmi*.fc${RELEASE}.${ARCH}.rpm
akmods --force --kernels "${KERNEL}" --kmod hp-wmi
modinfo /usr/lib/modules/${KERNEL}/extra/hp-wmi/hp-wmi.ko.xz  > /dev/null \
|| (find /var/cache/akmods/hp-wmi/ -name \*.log -print -exec cat {} \; && exit 1)
rm -f /etc/yum.repos.d/_copr_ublue-os-akmods.repo