#!/bin/sh -e
# Copyright (c) 2013 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This is a distro-specific bootstrap script, sourced from main.sh, and as such
# has access to all of the variables set by main.sh, namely $tmp (the temporary
# directory), $INSTALLERDIR/$DISTRO, $RELEASE, $ARCH, and $MIRROR.

# This code is loosely based on a script found on the Arch Linux Wiki:
# https://wiki.archlinux.org/index.php/Install_from_Existing_Linux

#REPOS='core community extra'

#if [ "$ARCH" = 'armv7h' ]; then
#    REPOS="$REPOS alarm aur"
#fi

# Packages to install in the bootstrap chroot. Dependencies are automatically
# fetched, but finding a suitable virtual package is not supported, so we have
# to list them manually:
# - bash provides sh
# - gawk provides awk
PACKAGES_BOOTSTRAP="perl-base urpmi"
# Packages we do not want to install (even if they are dependencies)
# FIXME: This is probably a bad idea
PACKAGES_BOOTSTRAP_IGNORE=""

#LIST="$tmp/list"
#FETCHDIRDB="$tmp/db"
#FETCHDIRPKG="$tmp/packages"
#BOOTSTRAPCHROOT="$tmp/$subdir"

#curlparams="--retry 3"
# Display progress bar only if we are outputing to a tty
#if [ -t 2 ]; then
#    curlparams="$curlparams -#"
#fi

#mkdir -p "$FETCHDIRDB" "$FETCHDIRPKG" "$BOOTSTRAPCHROOT"

#echo "Fetching repository packages list..." 1>&2
# Fetch Arch package database
#for REPO in $REPOS; do
#    echo "Fetching $REPO..." 1>&2
#    MIRRORBASE="`echo $MIRROR | sed -e "s/\\$repo/$REPO/" \
#                                    -e "s/\\$arch/$ARCH/"`"
#    curl $curlparams -o "$FETCHDIRDB/$REPO.db" "$MIRRORBASE/$REPO.db" 1>&2
    # Create package list in this format: $REPO:package-version
#    tar tf "$FETCHDIRDB/$REPO.db" \
#        | sed -n 's|^\(.*\)/$|'"$REPO:"'\1|p' >> "$LIST"
#done

# Get the value of a field in the Arch package database
# getvaluedb repo pkgver [desc|depends] field
#getdbfield() {
#    REPO="$FETCHDIRDB/$1.db"
#    FILE="$2/$3"
#    FIELD="$4"
    # Extract the relevant file
#    tar xf "$REPO" -O "$FILE" | awk '
#        /^$/ { m = 0 }
#        m { print }
#        /^%'"$FIELD"'%$/ { m = 1 }
#    '
#    return 0
#}

echo "Determining packages..." 1>&2
missing="$PACKAGES_BOOTSTRAP"
installed=""
bootstrappkg=""

# Install packages, taking care of dependencies:
# - Install all packages in $missing that have not been installed already.
# - Record all dependencies in $nextmissing
# - Set missing=nextmissing
# - Loop until $missing is empty

while [ -n "$missing" ]; do
    nextmissing=""
    for PACKAGE in $missing; do
        inst='y'

        #This following line tells us what rpms can provide $PACKAGE      
        rpm="awk -F@ '/^@provides@/ { pro = index($0, $PACKAGE) } /^@info@/ && pro { print $3 }' synthesis.hdlist"
	echo "These are the rpms that provide $PACKAGE"
        
        # Determine what the $PACKAGE rpm is called and allocate it to $urpmivar
        urpmivar="`awk -F "@" '/@info@'"$rpm"'-.[^A-Za-z]/ { print $3}' synthesis.hdlist`"
        echo "Required package is known as $urpmivar"
        # Required package is now known as $urpmivar
        # Do not install if already installed, or in ignore list
        for IPKG in $installed $PACKAGES_BOOTSTRAP_IGNORE; do
            if [ "$IPKG" = "$urpmivar" ]; then
                inst='n'
                break
            fi
        done

        if [ "$inst" = 'y' ]; then
          echo "$PACKAGE is not installed"
          echo "This is required & we would download and install '"$urpmivar"'" 1>&2
            
            
#            PKG="`grep ":$PACKAGE-[0-9]" "$LIST" | head -n 1`"
#            if [ -z "$PKG" ]; then
#                echo "Cannot find package $PACKAGE..." 1>&2
#                exit 1
#            fi

            
#            REPO="`echo $PKG | cut -f 1 -d:`"
#            PKGVER="`echo $PKG | cut -f 2 -d:`"
#            FILE="`getdbfield "$REPO" "$PKGVER" "desc" "FILENAME"`"
#            MIRRORBASE="`echo $MIRROR | sed -e "s/\\$repo/$REPO/" \
#                                            -e "s/\\$arch/$ARCH/"`"
#            curl $curlparams -o "$FETCHDIRPKG/$FILE" "$MIRRORBASE/$FILE" 1>&2
#            tar --warning=no-unknown-keyword -xkf "$FETCHDIRPKG/$FILE" -C "$BOOTSTRAPCHROOT"

            # Get list of dependencies (real and virtual) for $PACKAGE

            ndep=`awk -F@ '$2 == "requires" { req = $0; next } /^@info@'"$urpmivar"'/ { $0 = req; for (i = 3; i <= NF; i++) print $i }' synthesis.hdlist`
	    echo "These are the dependencies:   $ndep"


            
#            ndep="`getdbfield "$REPO" "$PKGVER" "depends" "DEPENDS" \
#                     | sed -n -e 's/^\([^<>=]*\).*$/\1/p' | tr '\n' ' '`"

            # Some packages provide virtual packages (e.g. bash provides sh):
            # Add those to the installed list
#            nprovides="`getdbfield "$REPO" "$PKGVER" "depends" "PROVIDES" \
#                          | tr '\n' ' '`"

            bootstrappkg="$bootstrappkg $PACKAGE"
            installed="$installed $nprovides $PACKAGE"
            nextmissing="$nextmissing $ndep"
#           rm "$BOOTSTRAPCHROOT/.PKGINFO"
        fi
    done

    missing="$nextmissing"
done

# Move databases to bootstrap fs
#mkdir -p "$BOOTSTRAPCHROOT/var/lib/pacman/sync"
#mv "$FETCHDIRDB"/*.db "$BOOTSTRAPCHROOT/var/lib/pacman/sync"
# Move package tarballs, so we can reinstall them properly
#mkdir -p "$BOOTSTRAPCHROOT/var/cache/pacman/pkg"
#mv "$FETCHDIRPKG"/* "$BOOTSTRAPCHROOT/var/cache/pacman/pkg"

#echo "arch" > "$BOOTSTRAPCHROOT/etc/hostname"
#sed -i 's/^[ \t]*SigLevel[ \t].*/SigLevel = Never/' \
#    "$BOOTSTRAPCHROOT/etc/pacman.conf"
#sed -i 's/^[ \t]*Architecture[ \t].*/Architecture = '"$ARCH"'/' \
#    "$BOOTSTRAPCHROOT/etc/pacman.conf"

#echo "$bootstrappkg" > "$BOOTSTRAPCHROOT"/crouton-bootstrap-pkg
