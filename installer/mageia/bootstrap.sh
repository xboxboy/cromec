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

# Grab latest package listings: 
echo 'Downloading mirror package listing: synthesis.hdlist.cz'
wget -O $tmp/synthesis.hdlist.cz $MIRROR/media_info/synthesis.hdlist.cz
# eg: wget -O $tmp/synthesis.hdlist.cz http://ftp.aarnet.edu.au/pub/mageia/distrib/3/x86_64/media/core/release/media_info/synthesis.hdlist.cz 

# Decompress package listing: 
echo 'Decompressing synthesis.hdlist.cz' 
gunzip -dvS.cz synthesis.hdlist.cz
# Create readable list of all package names: Saved as mirrorrpmlist.txt
echo 'Creating list of packages on mirror in /release'
awk -F "@" '/@info@/ { print $3 }' synthesis.hdlist > $tmp/mirrorrpmlist.txt

# Add the necessary debootstrap executables and packages required list
newpath="$PATH:$tmp"
cp "$INSTALLERDIR/$DISTRO/bash_rpm_cpio.sh" "$INSTALLERDIR/$DISTRO/bash_cpio.sh" "$INSTALLERDIR/$DISTRO/mageia3_rpms_req.txt" "$tmp/"
chmod 755 "$tmp/bash_rpm_cpio" "$tmp/bash_cpio.sh"

# Determine packages full names including version: Then gather packages for chroot environment
echo 'Downloading packages required for bootstrap'
for name in $(< $INSTALLERDIR/$DISTRO/mageia3_rpms_req.txt);
do
  wgetvar=$(grep "^$name-[0-9]" /$tmp/mirrorrpmlist.txt;)
  echo 'Package name and version :' $wgetvar
  echo 'Downloading package'
  wget $MIRROR/${wgetvar} -P $tmp "$name.rpm"
done

#filesystem* rpm must be extracted first, or bootstrap filesystem will not suit rpm (package manager): Must be run from $tmp directory
echo 'creating Mageia ready filesystem'
./bash_rpm_cpio.sh filesystem.rpm | ./bash_cpio.sh -idmv

# Create /dev in chroot
mkdir /$tmp/$subdir/dev

# extraction of packages from host system into intended chroot environment: Must be run from $tmp directory
echo 'Extracting packages into Chroot file system'
find . -type f -name "*".rpm | xargs -n1 -ifile sh -c "./bash_rpm_cpio.sh file | ./bash_cpio.sh -idv"
