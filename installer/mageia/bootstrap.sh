#!/bin/sh -e
# Copyright (c) 2013 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This is a distro-specific bootstrap script, sourced from main.sh, and as such
# has access to all of the variables set by main.sh, namely $tmp (the temporary
# directory), $INSTALLERDIR/$DISTRO, $RELEASE, $ARCH, and $MIRROR.

# Grab the latest release of debootstrap
#echo 'Downloading latest debootstrap...' 1>&2
#d='http://anonscm.debian.org/gitweb/?p=d-i/debootstrap.git;a=snapshot;h=HEAD;sf=tgz'
#if ! wget -O- --no-verbose --timeout=60 -t2 "$d" \
#        | tar -C "$tmp" --strip-components=1 -zx 2>/dev/null; then
#    echo 'Download from Debian gitweb failed. Trying latest release...' 1>&2
#    d='http://ftp.debian.org/debian/pool/main/d/debootstrap/'
#    f="`wget -O- --no-verbose --timeout=60 -t2 "$d" \
#            | sed -ne 's ^.*\(debootstrap_[0-9.]*.tar.gz\).*$ \1 p' \
#            | tail -n 1`"
#    if [ -z "$f" ]; then
#        error 1 'Failed to download debootstrap.
#Check your internet connection or proxy settings and try again.'
#    fi
#    v="${f#*_}"
#    v="${v%.tar.gz}"
#    echo "Downloading debootstrap version $v..." 1>&2
#    if ! wget -O- --no-verbose --timeout=60 -t2 "$d$f" \
#            | tar -C "$tmp" --strip-components=1 -zx 2>/dev/null; then
#        error 1 'Failed to download debootstrap.'
#    fi
#fi

# Grab latest package listings: Requires modification to suit varible mirror
echo 'Downloading synthesis.hdlist.cz"
wget http://ftp.aarnet.edu.au/pub/mageia/distrib/3/x86_64/media/core/release/media_info/synthesis.hdlist.cz
# Decompress package listing: Non-verbose as gzip complaints of non *.zip file
echo 'Decompressing synthesis.hdlist.cz'
gunzip -fdS.cz synthesis.hdlist.cz
# Create readable list of all package names: Saved as rpmlist.txt
echo 'Creating package list'
awk -F "@" '/@info@/ { print $3 }' synthesis.hdlist > rpmlist.txt
# From github 3 scripts required: list of required rpms, rpm2cpio bash script, cpio bash script
# When compressed as tarball, links to be removed: Files will be in tarball
echo 'downloading list of packages required for bootstrap'
wget https://raw.github.com/xboxboy/cromec/master/installer/mageia/mageia3_rpms_req.txt
echo 'downloading bash implementation of rpm2cpio script'
wget https://raw.github.com/xboxboy/cromec/master/installer/mageia/bash_rpm_cpio.sh
echo 'downloading bash implementation of cpio'
wget https://raw.github.com/xboxboy/cromec/master/installer/mageia/bash_cpio.sh
# Determine packages full names including version and gather rpms for environment: Only supports X86_64 at present:
echo 'Downloading packages required for bootstrap'
for name in $(< /chroottest/mageia3_rpms_req.txt);
do
  wgetvar=$(grep "^$name-[0-9]" /chroottest/rpmlist.txt;)
  echo $wgetvar
  wget http://ftp.aarnet.edu.au/pub/mageia/distrib/3/x86_64/media/core/release/${wgetvar} -O "$name.rpm"
done
#filesystem* rpm must be extracted first, or bootstrap filesystem will not suit rpm (package manager)
echo 'creating Mageia ready filesystem'
./bash_rpm_cpio.sh filesystem.rpm | ./bash_cpio.sh -idmv
# Create /dev in chroot
mkdir /chroottest/dev
# extraction of packages from host system into intended chroot environment
find . -type f -name "*".rpm | xargs -n1 -ifile sh -c "./bash_rpm_cpio.sh file | ./bash_cpio.sh -idv"







# Add the necessary debootstrap executables
#newpath="$PATH:$tmp"
#cp "$INSTALLERDIR/$DISTRO/ar" "$INSTALLERDIR/$DISTRO/pkgdetails" "$tmp/"
#chmod 755 "$tmp/ar" "$tmp/pkgdetails"

# debootstrap wants a file to initialize /dev with, but we don't actually
# want any files there. Create an empty tarball that it can extract.
#tar -czf "$tmp/devices.tar.gz" -T /dev/null

# Grab the release and drop it into the subdirectory
#echo 'Downloading bootstrap files...' 1>&2
#PATH="$newpath" DEBOOTSTRAP_DIR="$tmp" $FAKEROOT \
    "$tmp/debootstrap" --foreign --arch="$ARCH" "$RELEASE" \
                       "$tmp/$subdir" "$MIRROR" 1>&2