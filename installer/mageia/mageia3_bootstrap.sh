#! /bin/bash

# This script has a fixed mirror address: Mirror variations to be added!

# Create chroot directory: # testing in ~ at present

mkdir ~/chroottest

# Enter chroottest directory

cd ~/chroottest

# Get latest rpm listing : Again as above, mirror is fixed

wget http://ftp.aarnet.edu.au/pub/mageia/distrib/3/x86_64/media/core/release/media_info/synthesis.hdlist.cz

# Decompress mirror rpm listing: Non verbose as gzip complains as suffix is cz

gunzip -fdS.cz synthesis.hdlist.cz

# Determine full name and version of all rpms in /core on mirror from mirror rpm listing

awk -F "@" '/@info@/ { print $3 }' synthesis.hdlist > rpmlist.txt

# Get list of required rpm's for chroot environment: From github

wget https://raw.github.com/xboxboy/cromec/master/installer/mageia/mageia3_rpms_req.txt

# Determine rpm full name and version and gather rpms for environment: Only supports X86_64 at present: arch detection and response to be added!

for name in $(< ~/chroottest/mageia3_rpms_req.txt);
do
  wgetvar=$(grep "^$name-[0-9]" ~/chroottest/rpmlist.txt;)
  echo $wgetvar
  wget --spider http://ftp.aarnet.edu.au/pub/mageia/distrib/3/x86_64/media/core/release/${wgetvar}
done