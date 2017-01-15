#!/sbin/sh
# 
# /system/addon.d/999-customkernel.sh
# During an upgrade, this script backs up the EMMC boot (Kernel) partition,
# then ROM Kernel is allowed to flash and finally the previous custom
# Kernel is restored.
#

# Functions
. /tmp/backuptool.functions
block=/dev/block/platform/msm_sdcc.1/by-name/boot;
bkp_synapse=/data/UKM/backup/Synapse.apk;
synapse=/system/priv-app/Synapse/Synapse.apk;

set_perm_recursive() {
  dirs=$(echo $* | $bb awk '{ print substr($0, index($0,$5)) }');
  for i in $dirs; do
    chown -R $1.$2 $i; chown -R $1:$2 $i;
    find "$i" -type d -exec chmod $3 {} +;
    find "$i" -type f -exec chmod $4 {} +;
  done;
}

case "$1" in
  backup)
    # Extract custom Kernel.
    if [ -e "$block" ]; then
      dd if=$block of=/tmp/custom.img;
    fi;
  ;;
  restore)
    # Push Synapse app to system back again.
    if [ -f "$bkp_synapse" ]; then
      mkdir -p /system/priv-app/Synapse;
      cp -f $bkp_synapse $synapse;
      set_perm_recursive 0 0 755 644 /system/priv-app;
    fi;
  ;;
  pre-backup)
    # Stub
  ;;
  post-backup)
    # Stub
  ;;
  pre-restore)
    # Stub
  ;;
  post-restore)
    # Wait 5s and restore the custom Kernel.
    while sleep 5; do
      [ -e /tmp/custom.img -a -e "$block" ] && dd if=/tmp/custom.img of=$block;
      exit;
    done&
  ;;
esac;
