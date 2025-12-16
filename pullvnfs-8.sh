#!/bin/sh

#  Copyright (c) 2025, Lawrence Berkeley National Laboratory.  All rights reserved.
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions
#  are met:
#
#    * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#
#    * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in
#       the documentation and/or other materials provided with the
#       distribution.
#
#  THIS SOFTWARE IS PROVIDED BY LAWRENCE BERKELEY NATIONAL LABORATORY "AS IS" AND ANY EXPRESS
#  OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
#  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
#  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
#  BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
#  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
#  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
#  IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

TIMESTAMP=`date +%Y%m%d-%H:%M:%S`
HOST=`hostname -s`
RSYNC_HOST="hpcs-runner.lbl.gov"
CHROOT_BASE="/var/lib/warewulf/chroots"
ERROR="usage: pullvnfs-8.sh -v [DIST]-[BRANCH]-[GITVER] [-t|--test]"
PULL_LOG="/var/log/vnfspull.log"

# Set up getopt style argument handling
if [ "$*" == "" ]; then
        echo "$ERROR"
        exit 1
fi      

TEMP=`getopt -o tv: --long test,vnfs: -n 'parse-options' -- "$@"`

if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi

eval set -- "$TEMP"

while true; do
        case "$1" in
                -v|--vnfs) VNFS=$2 ; shift 2 ;;
                -t|--test) TEST=1; shift ;;
                --) shift ; break ;;
                *) break ;;
        esac
done

# Check if we've been told this is a test VNFS
if [ "$TEST" == "1" ]; then
        CHROOT_BASE="/var/lib/warewulf/chroots/test"
fi

if [ "$VNFS" == "" ]; then
        echo "$ERROR"
        exit 1
fi

DIST=`echo "$VNFS" | tr -s '-' ' ' | awk '{print $1}'`
BRANCH=`echo "$VNFS" | tr -s '-' ' ' | awk '{print $2}'`
GITVER=`echo "$VNFS" | tr -s '-' ' ' | awk '{print $3}'`

echo $DIST-$BRANCH-$GITVER
mkdir -p $CHROOT_BASE/$DIST-$BRANCH/rootfs
rsync -axHP --delete --exclude=/dev/* $RSYNC_HOST::chroots/$DIST-$BRANCH-$GITVER/ $CHROOT_BASE/$DIST-$BRANCH/rootfs/

echo "$GITVER" > $CHROOT_BASE/$DIST-$BRANCH/.vnfsbuild

wwctl image build $DIST-$BRANCH

echo "$TIMESTAMP $DIST-$BRANCH-$GITVER" >> $PULL_LOG
