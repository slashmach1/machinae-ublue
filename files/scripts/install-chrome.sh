#!/bin/bash

set -ouex pipefail

# On libostree systems, /opt is a symlink to /var/opt,
# which actually only exists on the live system. /var is
# a separate mutable, stateful FS that's overlaid onto
# the ostree rootfs. Therefore we need to install it into
# /usr/lib/google instead, and dynamically create a
# symbolic link /opt/google => /usr/lib/google upon
# boot.

# Prepare staging directory
mkdir -p /var/opt # -p just in case it exists

# Prepare alternatives directory
mkdir -p /var/lib/alternatives

# Setup repo
rpm-ostree install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm 
cat << EOF > /etc/yum.repos.d/google-chrome.repo
[google-chrome]
name=google-chrome
baseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-google
EOF
# Import signing key
curl --retry 3 --retry-delay 2 --retry-all-errors -sL \
  -o /etc/pki/rpm-gpg/RPM-GPG-KEY-google \
  https://dl.google.com/linux/linux_signing_key.pub
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-google

# Now let's install the packages.
rpm-ostree install google-chrome-stable
rpm-ostree install ffmpeg gstreamer1-plugin-libav gstreamer1-plugins-bad-free-extras gstreamer1-plugins-bad-freeworld gstreamer1-plugins-ugly gstreamer1-vaapi libva-nvidia-driver intel-media-driver libva-intel-driver
# Clean up the yum repo (updates are baked into new images)
rm /etc/yum.repos.d/google-chrome.repo -f
mv /var/opt/google /usr/lib/google # move this over here

#####
# Register path symlink
# We do this via tmpfiles.d so that it is created by the live system.
cat >/usr/lib/tmpfiles.d/google.conf <<EOF
L  /opt/google  -  -  -  -  /usr/lib/google
EOF