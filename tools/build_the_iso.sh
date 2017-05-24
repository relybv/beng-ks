#!/bin/bash
# script to generate bios or uefi boot image

# adjust as needed
# SRCISO=~/CentOS-7-x86_64-DVD.iso  # rhel-server-7.3-x86_64-boot.iso, CentOS-7-x86_64-Minimal.iso , etc
SRCISO=~/rhel-server-7.3-x86_64-boot.iso
OSNAME=RHEL                     # pick RHEL or CENTOS
OSVERSION=7.3                   # rhel 7.2, 7.3, centos, 6,7, etc
OSARCH=x86_64                   # for now only x86_64

### start of code ###
NOW=`date +%Y%m%d-%H%M%S`
OSID="${OSNAME}-${OSVERSION} ${OSARCH}"
TRGTISO="ks-${OSNAME}-${OSVERSION}-${NOW}-uefi-${OSARCH}.iso"
TRGISOBIOS="ks-${OSNAME}-${OSVERSION}-${NOW}-bios-${OSARCH}.iso"
CURDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ISODIR=`mktemp -d -p "$CURDIR"`
TRGTDIR=`mktemp -d -p "$CURDIR"`

# deletes the iso directory
function cleanup {      
  cd $CURDIR
  if mountpoint -q $ISODIR; then
    # echo "Unmounting $ISODIR"
    umount $ISODIR
  else
    echo "$ISODIR is no mountpoint"
  fi
  rmdir "$ISODIR"
  # echo "Deleted iso directory $ISODIR"
  if [ -d "$TRGTDIR" ]; then
    rm -rf $TRGTDIR
    # echo "Deleted target dir $TRGTDIR"
  fi
}

# check if iso dir was created
if [[ ! "$ISODIR" || ! -d "$ISODIR" ]]; then
  echo "Could not create iso dir"
  exit 1
fi

# check if target dir was created
if [[ ! "$TRGTDIR" || ! -d "$TRGTDIR" ]]; then
  echo "Could not create target dir"
  exit 1
fi

# register the cleanup function to be called on the EXIT signal
trap cleanup EXIT

# chack permissions, mount needs root
if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root."
  exit 1
fi

# check for mkisofs
if which mkisofs >/dev/null; then
  echo "mkisofs exists"
else
  echo "mkisofs does not exist, try to install"
  exit 1
fi

# check iso location
if [ ! -f $SRCISO ]; then
  echo "Iso image not found: $SRCISO"
  exit 1
fi

echo "Iso: $SRCISO"
echo "OS id: $OSID"
echo "Currentdir: $CURDIR"
echo "Isodir: $ISODIR"
echo "Target iso: $TRGTISO"
echo "Target dir: $TRGTDIR"

echo "Mounting iso filesystem"
mount -o loop --read-only $SRCISO $ISODIR

echo "copy isolinux to temp directory"
rsync -rv $ISODIR/* $TRGTDIR

echo "generate isolinux.cfg"
cat templates/isolinux.header > $TRGTDIR/isolinux/isolinux.cfg
./yaml2isolinux.sh >> $TRGTDIR/isolinux/isolinux.cfg
cat templates/isolinux.footer >> $TRGTDIR/isolinux/isolinux.cfg

echo "generate grub.cfg"
cat templates/grub.header > $TRGTDIR/EFI/BOOT/grub.cfg
./yaml2grub.sh >> $TRGTDIR/EFI/BOOT/grub.cfg
cat templates/grub.footer >> $TRGTDIR/EFI/BOOT/grub.cfg
cd $TRGTDIR

echo "Creating new bootable uefi iso"
mkisofs -U -A "$OSID" -V "$OSID" -volset "$OSID" -J -joliet-long -r -v -T -x ./lost+found -o $CURDIR/$TRGTISO -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -e images/efiboot.img -no-emul-boot .
echo "OS id: $OSID"
echo "Generated iso: $CURDIR/$TRGTISO"

echo "Create new bootable bios iso"
#cp ~root/beng-rely/files/isolinux.cfg /ISO/dvd_7/isolinux/isolinux.cfg
#mkisofs -o $CURDIR/$TRGISOBIOS -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -R -J -v -T .
echo "Generated iso: $CURDIR/$TRGISOBIOS"
