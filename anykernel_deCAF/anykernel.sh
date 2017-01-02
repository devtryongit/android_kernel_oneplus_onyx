# AnyKernel2 Script
#
# Original and credits: osm0sis @ xda-developers
#
# Modified by RJ Murdok

############### AnyKernel setup start ############### 

# EDIFY properties
do.devicecheck=1
do.initd=0
do.modules=1
do.cleanup=1
device.name1=OnePlus
device.name2=ONE
device.name3=onyx
device.name4=E1005
device.name5=E1003
device.name6=E1001
device.name7=E1000

# shell variables
block=/dev/block/platform/msm_sdcc.1/by-name/boot;
add_seandroidenforce=0
supersu_exclusions=""
is_slot_device=0;

############### AnyKernel setup end ############### 

## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. /tmp/anykernel/tools/ak2-core.sh;

# dump current kernel
dump_boot;

############### Ramdisk customization start ###############

# AnyKernel permissions
chmod 775 $ramdisk/sbin
chmod 755 $ramdisk/sbin/busybox

chmod 775 $ramdisk/res

# insert initd scripts
cp -fp $patch/init.d/* $initd
chmod -R 766 $initd

# remove mpdecsion binary
mv $bindir/mpdecision $bindir/mpdecision-rm

# remove qcom thermal engine
mv /system/etc/thermal-engine-8974.conf /system/etc/thermal-engine-8974-rm

# xPrivacy
# Thanks to @Shadowghoster & @@laufersteppenwolf
param=$(grep "xprivacy" service_contexts)
if [ -z $param ]; then
    echo -ne "xprivacy453                               u:object_r:system_server_service:s0\n" >> service_contexts
fi

# ramdisk changes
backup_file init.rc;
replace_string init.rc "chmod 0660 /sys/module/lowmemorykiller/parameters/adj" "chmod 0220 /sys/module/lowmemorykiller/parameters/adj" "chmod 0660 /sys/module/lowmemorykiller/parameters/adj";
replace_string init.rc "chmod 0660 /sys/module/lowmemorykiller/parameters/minfree" "chmod 0220 /sys/module/lowmemorykiller/parameters/minfree" "chmod 0660 /sys/module/lowmemorykiller/parameters/minfree";

############### Ramdisk customization end ###############

# write new kernel
write_boot;
