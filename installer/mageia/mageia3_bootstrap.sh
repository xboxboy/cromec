#! /bin/bash

# Script needs to be run as root: or extraction of filesystem-xxxx.release.arch.rpm will fail, and the install will break.

# This script has a fixed mirror address: Mirror variations to be added!
# For future reference: url=http://mirrors.mageia.org/api/mageia.(release).(arch).list; wget -q ${url} -O - | grep rsync:       provides list of official mirrors where release & arch suit the local system

# Create chroot directory: # testing in ~ at present

mkdir /chroottest

# Enter chroottest directory

cd /chroottest

# Get latest rpm listing : Again as above, mirror is fixed

wget http://ftp.aarnet.edu.au/pub/mageia/distrib/3/x86_64/media/core/release/media_info/synthesis.hdlist.cz

# Decompress mirror rpm listing: Non verbose as gzip complains as suffix is cz

gunzip -fdS.cz synthesis.hdlist.cz

# Determine full name and version of all rpms in /core on mirror from mirror rpm listing

awk -F "@" '/@info@/ { print $3 }' synthesis.hdlist > rpmlist.txt

# From github 3 scripts required: list of required rpms, rpm2cpio bash script, cpio bash script
# Get list of required rpm's for chroot environment: 

wget https://raw.github.com/xboxboy/cromec/master/installer/mageia/mageia3_rpms_req.txt
wget https://raw.github.com/xboxboy/cromec/master/installer/mageia/bash_rpm_cpio.sh
wget https://raw.github.com/xboxboy/cromec/master/installer/mageia/bash_cpio.sh

# Make bash scripts executable

chmod 555 bash_rpm_cpio.sh
chmod 555 bash_cpio.sh

# Determine rpm full name and version and gather rpms for environment: Only supports X86_64 at present: arch detection and response to be added!

for name in $(< /chroottest/mageia3_rpms_req.txt);
do
  wgetvar=$(grep "^$name-[0-9]" /chroottest/rpmlist.txt;)
  echo $wgetvar
  wget http://ftp.aarnet.edu.au/pub/mageia/distrib/3/x86_64/media/core/release/${wgetvar} -O "$name.rpm"
done

#Test download filesystem rpm for extraction: Manually

# wget http://ftp.aarnet.edu.au/pub/mageia/distrib/3/x86_64/media/core/release/filesystem-2.1.9-20.mga3.x86_64.rpm

# added a perl depenency

# wget http://mirror.aarnet.edu.au/pub/mageia/distrib/3/x86_64/media/core/release/perl-List-MoreUtils-0.330.0-3.mga3.x86_64.rpm

#filesystem* rpm must be extracted first, or bootstrap filesystem will not suit rpm (package manager)

./bash_rpm_cpio.sh filesystem.rpm | ./bash_cpio.sh -idmv

#All required rpm's to be extracted into filesystem using bash rpm extraction tools

find . -type f -name "*".rpm | xargs -n1 -ifile sh -c "./bash_rpm_cpio.sh file | ./bash_cpio.sh -idv"

# Create /dev in chroot

mkdir /chroottest/dev

#We need to bind to host system directories

mount -o bind /proc /chroottest/proc
mount -o bind /dev /chroottest/dev
mount -o bind /sys /chroottest/sys

# Copy host resolve.conf for networking : Needs to overwrite existing file in chroot

cp -fr /etc/resolv.conf /chroottest/etc/resolv.conf

#enter chroot

# chroot /chroottest/

# Use RPM to reinstall all rpms: Build rpm database

# A: find . -type f -name "*".rpm | xargs -n1 -ifile /bin/rpm file -iv --nodeps --replacepkgs

# Urpmi not working due to locale problems : May not need this following export line

# export LC_ALL=en_AU.UTF-8 

# Add mirror list to urpmi

# urpmi.addmedia --distrib --mirrorlist '$MIRRORLIST'

# B: urpmi.addmedia --distrib ftp://ftp.mirror.aarnet.edu.au/pub/mageia/distrib/3/x86_64
