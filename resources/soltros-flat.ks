lang en_US.UTF-8
keyboard us
timezone UTC --isUtc
auth --useshadow --enablemd5
selinux --disabled
firewall --disabled
services --enabled=sshd,NetworkManager
bootloader --timeout=0 --location=mbr --append="quiet"

# Use minimal installation
install
text
reboot

repo --name=fedora --baseurl=https://mirror.stream.centos.org/9-stream/BaseOS/x86_64/os/

%packages --excludedocs --nocore --inst-langs=en --exclude-weakdeps
@core
bash
coreutils
dnf5
dnf5-plugins
fedora-release-container
glibc-minimal-langpack
rootfiles
rpm
sudo
tar
tzdata
util-linux-core
vim-minimal

# Important: These exclusions were removed to avoid dependency breakage:
# -dosfstools
# -e2fsprogs
# -fuse-libs
# -glibc-langpack-en
# -gnupg2-smime
# -grubby
# -kernel
# -langpacks-en
# -langpacks-en_GB
# -libss
# -pinentry
# -shared-mime-info
# -sssd-client
# -trousers
# -util-linux
# -xkeyboard-config
%end

%post
# Basic hostname and MOTD
echo "soltros" > /etc/hostname
echo "Welcome to SoltrOS Minimal" > /etc/motd

# Enable systemd-resolved
ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf

# Optional: Custom branding or config tweaks
# mkdir -p /etc/soltros
# echo "soltros-live" > /etc/soltros/image-type

%end

%post --nochroot
# liveimg is needed to build the squashfs root
liveimg --timeout=0 --title="SoltrOS Minimal"
%end
