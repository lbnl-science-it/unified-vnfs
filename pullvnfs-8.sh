#!/bin/sh

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
