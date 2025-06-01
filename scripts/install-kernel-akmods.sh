#!/usr/bin/bash
set -eoux pipefail
echo "::group::Executing install-kernel-akmods"
trap 'echo "::endgroup::"' EXIT
dnf5 -y remove --no-autoremove kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra
dnf5 -y install /tmp/kernel-rpms/kernel-[0-9]*.rpm /tmp/kernel-rpms/kernel-core-*.rpm /tmp/kernel-rpms/kernel-modules-*.rpm /tmp/kernel-rpms/kernel-devel-*.rpm
dnf5 versionlock add kernel kernel-devel kernel-devel-matched kernel-core kernel-modules kernel-modules-core kernel-modules-extra kernel-uki-virt
dnf5 -y install /tmp/akmods-rpms/kmods/*.rpm /tmp/akmods-extra-rpms/kmods/*.rpm
