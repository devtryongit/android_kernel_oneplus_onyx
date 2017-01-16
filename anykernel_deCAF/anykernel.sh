# AnyKernel2 Ramdisk Mod Script
# osm0sis @ xda-developers
# modified by RenderBroken for the G2
# enhanced as fuck by GalaticStryder!
# More stuffs by CertifiedBlyndGuy

# Setup
permissive=1
do.binaries=1
do.devicecheck=1
do.initd=1
do.wallpaper=1
do.ukm=1
do.cleanup=1
device.name1=onyx
device.name2=E1005
device.name3=E1003
device.name4=E1001
device.name5=E1000
device.name6=OnePlus
device.name7=ONE
device.name8=oneplus

block=/dev/block/platform/msm_sdcc.1/by-name/boot;
initd=/system/etc/init.d;
ramdisk=/tmp/anykernel/ramdisk;
ramdisk-new=/tmp/anykernel/ramdisk-new;
bin=/tmp/anykernel/tools;
split_img=/tmp/anykernel/split_img;
patch=/tmp/anykernel/patch;
is_slot_device=0;

chmod -R 755 $bin;
mkdir -p $ramdisk $ramdisk-new $split_img;

if [ "$is_slot_device" == 1 ]; then
  slot=$(getprop ro.boot.slot_suffix 2>/dev/null);
  test ! "$slot" && slot=$(grep -o 'androidboot.slot_suffix=.*$' /proc/cmdline | cut -d\  -f1 | cut -d= -f2);
  test "$slot" && block=$block$slot;
  if [ $? != 0 -o ! -e "$block" ]; then
    ui_print " "; ui_print "Unable to determine active boot slot. Aborting..."; exit 1;
  fi;
fi;

OUTFD=/proc/self/fd/$1;

# ui_print <text>
ui_print() { echo -e "ui_print $1\nui_print" > $OUTFD; }

# contains <string> <substring>
contains() { test "${1#*$2}" != "$1" && return 0 || return 1; }

# dump boot and extract ramdisk
dump_boot() {
  dd if=$block of=/tmp/anykernel/boot.img;
  $bin/unpackbootimg -i /tmp/anykernel/boot.img -o $split_img;
  if [ $? != 0 ]; then
    ui_print " "; ui_print "Dumping/splitting image failed. Aborting..."; exit 1;
  fi;
  mv -f $ramdisk /tmp/anykernel/rdtmp;
  mkdir -p $ramdisk;
  cd $ramdisk;
  gunzip -c $split_img/boot.img-ramdisk.gz | cpio -i;
  if [ $? != 0 -o -z "$(ls $ramdisk)" ]; then
    ui_print " "; ui_print "Unpacking ramdisk failed. Aborting..."; exit 1;
  fi;
  cp -af /tmp/anykernel/rdtmp/* $ramdisk;
}

# repack ramdisk then build and write image
write_boot() {
  cd $split_img;
  cmdline=`cat *-cmdline`;
  if [ $permissive == 1 ]; then
    if [[ cmdline == *"permissive"* ]]; then
      ui_print "Permissive SELinux mode detected, skipping...";
    else
      ui_print "Setting SELinux to permissive mode...";
      cmdline="$cmdline androidboot.selinux=permissive";
    fi;
  fi;
  board=`cat *-board`;
  base=`cat *-base`;
  pagesize=`cat *-pagesize`;
  kerneloff=`cat *-kerneloff`;
  ramdiskoff=`cat *-ramdiskoff`;
  tagsoff=`cat *-tagsoff`;
  osver=`cat *-osversion`;
  oslvl=`cat *-oslevel`;
  if [ -f *-second ]; then
    second=`ls *-second`;
    second="--second $split_img/$second";
    secondoff=`cat *-secondoff`;
    secondoff="--second_offset $secondoff";
  fi;
  if [ -f /tmp/anykernel/zImage ]; then
    ui_print "Detected kernel image as zImage.";
    kernel=/tmp/anykernel/zImage;
  elif [ -f /tmp/anykernel/zImage-dtb ]; then
    ui_print "Detected kernel image as zImage-dtb.";
    kernel=/tmp/anykernel/zImage-dtb;
  else
    ui_print "Looking for the kernel image...";
    kernel=`ls *-zImage`;
    kernel=$split_img/$kernel;
  fi;
  if [ -f /tmp/anykernel/dt.img ]; then
    ui_print "Found device tree image as dt.img.";
    dtimg="--dt /tmp/anykernel/dt.img";
  elif [ -f *-dtb ]; then
    ui_print "Looking for the device tree image...";
    dtimg=`ls *-dtb`;
    dtimg="--dt $split_img/$dtb";
  fi;
  cp -rf $ramdisk/* $ramdisk-new;
  cd $ramdisk-new;
  find . | cpio -H newc -o | gzip > /tmp/anykernel/ramdisk-new.cpio.gz;
  if [ $? != 0 ]; then
    ui_print " "; ui_print "Repacking ramdisk failed. Aborting..."; exit 1;
  fi;
  $bin/mkbootimg --kernel $kernel --ramdisk /tmp/anykernel/ramdisk-new.cpio.gz $second --cmdline "$cmdline" --board "$board" --base $base --pagesize $pagesize --kernel_offset $kerneloff --ramdisk_offset $ramdiskoff $secondoff --tags_offset $tagsoff --os_version "$osver" --os_patch_level "$oslvl" $dtimg --output /tmp/anykernel/boot-new.img;
  if [ $? != 0 ]; then
    ui_print " "; ui_print "Repacking image failed. Aborting..."; exit 1;
  elif [ `wc -c < /tmp/anykernel/boot-new.img` -gt `wc -c < /tmp/anykernel/boot.img` ]; then
    ui_print " "; ui_print "New image larger than boot partition. Aborting..."; exit 1;
  fi;
  if [ -f "/data/custom_boot_image_patch.sh" ]; then
    ash /data/custom_boot_image_patch.sh /tmp/anykernel/boot-new.img;
    if [ $? != 0 ]; then
      ui_print " "; ui_print "User script execution failed. Aborting..."; exit 1;
    fi;
  fi;
  # Bump that shit by @RenderBroken!
  ui_print "Bumping final boot image...";
  dd if=$bin/bump >> /tmp/anykernel/boot-new.img;
  dd if=/tmp/anykernel/boot-new.img of=$block;
}

# backup_file <file>
backup_file() { cp $1 $1~; }

# replace_string <file> <if search string> <original string> <replacement string>
replace_string() {
  if [ -z "$(grep "$2" $1)" ]; then
      sed -i "s;${3};${4};" $1;
  fi;
}

# replace_section <file> <begin search string> <end search string> <replacement string>
replace_section() {
  begin=`grep -n "$2" $1 | head -n1 | cut -d: -f1`;
  for end in `grep -n "$3" $1 | cut -d: -f1`; do
    if [ "$begin" -lt "$end" ]; then
      sed -i "/${2//\//\\/}/,/${3//\//\\/}/d" $1;
      sed -i "${begin}s;^;${4}\n;" $1;
      break;
    fi;
  done;
}

# remove_section <file> <begin search string> <end search string>
remove_section() {
  begin=`grep -n "$2" $1 | head -n1 | cut -d: -f1`;
  for end in `grep -n "$3" $1 | cut -d: -f1`; do
    if [ "$begin" -lt "$end" ]; then
      sed -i "/${2//\//\\/}/,/${3//\//\\/}/d" $1;
      break;
    fi;
  done;
}

# insert_line <file> <if search string> <before|after> <line match string> <inserted line>
insert_line() {
  if [ -z "$(grep "$2" $1)" ]; then
    case $3 in
      before) offset=0;;
      after) offset=1;;
    esac;
    line=$((`grep -n "$4" $1 | head -n1 | cut -d: -f1` + offset));
    sed -i "${line}s;^;${5}\n;" $1;
  fi;
}

# replace_line <file> <line replace string> <replacement line>
replace_line() {
  if [ ! -z "$(grep "$2" $1)" ]; then
    line=`grep -n "$2" $1 | head -n1 | cut -d: -f1`;
    sed -i "${line}s;.*;${3};" $1;
  fi;
}

# remove_line <file> <line match string>
remove_line() {
  if [ ! -z "$(grep "$2" $1)" ]; then
    line=`grep -n "$2" $1 | head -n1 | cut -d: -f1`;
    sed -i "${line}d" $1;
  fi;
}

# prepend_file <file> <if search string> <patch file>
prepend_file() {
  if [ -z "$(grep "$2" $1)" ]; then
    echo "$(cat $patch/$3 $1)" > $1;
  fi;
}

# insert_file <file> <if search string> <before|after> <line match string> <patch file>
insert_file() {
  if [ -z "$(grep "$2" $1)" ]; then
    case $3 in
      before) offset=0;;
      after) offset=1;;
    esac;
    line=$((`grep -n "$4" $1 | head -n1 | cut -d: -f1` + offset));
    sed -i "${line}s;^;\n;" $1;
    sed -i "$((line - 1))r $patch/$5" $1;
  fi;
}

# append_file <file> <if search string> <patch file>
append_file() {
  if [ -z "$(grep "$2" $1)" ]; then
    echo -ne "\n" >> $1;
    cat $patch/$3 >> $1;
    echo -ne "\n" >> $1;
  fi;
}

# replace_file <file> <permissions> <patch file>
replace_file() {
  cp -pf $patch/$3 $1;
  chmod $2 $1;
}

# patch_fstab <fstab file> <mount match name> <fs match type> <block|mount|fstype|options|flags> <original string> <replacement string>
patch_fstab() {
  entry=$(grep "$2" $1 | grep "$3");
  if [ -z "$(echo "$entry" | grep "$6")" ]; then
    case $4 in
      block) part=$(echo "$entry" | awk '{ print $1 }');;
      mount) part=$(echo "$entry" | awk '{ print $2 }');;
      fstype) part=$(echo "$entry" | awk '{ print $3 }');;
      options) part=$(echo "$entry" | awk '{ print $4 }');;
      flags) part=$(echo "$entry" | awk '{ print $5 }');;
    esac;
    newentry=$(echo "$entry" | sed "s;${part};${6};");
    sed -i "s;${entry};${newentry};" $1;
  fi;
}

chmod 755 /tmp/anykernel/ramdisk/sbin/busybox
chmod 755 /tmp/anykernel/ramdisk/sbin/uci
chmod -R 755 $ramdisk-new
dump_boot;

# Init.d
cp -fp $patch/init.d/* $initd
chmod -R 755 $initd

# Android version
if [ -f "/system/build.prop" ]; then
  SDK="$(grep "ro.build.version.sdk" "/system/build.prop" | cut -d '=' -f 2)";
  ui_print "Android SDK API: $SDK.";
  if [ "$SDK" -le "21" ]; then
    ui_print " "; ui_print "Android 5.0 and older is not supported. Aborting..."; exit 1;
  fi;
else
  ui_print " "; ui_print "No build.prop could be found. Aborting..."; exit 1;
fi;

# Properties
ui_print "Modifying properties...";
backup_file default.prop;
replace_string default.prop "ro.adb.secure=0" "ro.adb.secure=1" "ro.adb.secure=0";
replace_string default.prop "ro.secure=0" "ro.secure=1" "ro.secure=0";

# Init files
ui_print "Modifying init files...";
# LineageOS
if [ -f init.qcom.rc ]; then
  if [ "$SDK" -ge "24" ]; then
    ui_print "LineageOS 14.1 based ROM detected.";
  elif [ "$SDK" -eq "23" ]; then
    ui_print "LineageOS 13.0 based ROM detected.";
  elif [ "$SDK" -eq "22" ]; then
    ui_print "LineageOS 12.1 based ROM detected.";
  fi;
  backup_file init.qcom.rc;
  if [ -z "$(grep "zram0" init.qcom.rc)" ]; then
    ui_print "Injecting ZRAM support...";
    if [ "$SDK" -ge "23" ]; then
      insert_line init.qcom.rc "zram0" after "symlink /sdcard /storage/sdcard0" "\n    # Setup ZRAM\n    write /sys/block/zram0/comp_algorithm lz4\n    write /sys/block/zram0/max_comp_streams 2\n";
    elif [ "$SDK" -eq "22" ]; then
      insert_line init.qcom.rc "zram0" after "symlink /storage/usbdisk0 /storage/usb" "\n    # Setup ZRAM\n    write /sys/block/zram0/comp_algorithm lz4\n    write /sys/block/zram0/max_comp_streams 2\n";
    fi;
  else
    ui_print "Detected built-in ZRAM support, skipping...";
  fi;
  if [ -z "$(grep "swapon_all" init.qcom.rc)" ]; then
    ui_print "Injecting swap mount point...";
    insert_line init.qcom.rc "swapon_all" after "mount_all ./fstab.qcom" "    swapon_all ./fstab.qcom";
  else
    ui_print "Detected built-in swap support, skipping...";
  fi;
  ui_print "Injecting post-boot script support...";
  append_file init.qcom.rc "aries-post_boot" init.script.patch;
fi;
if [ -f fstab.qcom ]; then
  backup_file fstab.qcom;
  if [ -z "$(grep "zramsize" fstab.qcom)" ]; then
    # Add patch if ZRAM is not found in fstab.
    ui_print "Injecting ZRAM support fstab patch...";
    append_file fstab.qcom "zramsize" fstab.zram.patch;
  else
    # Set the proper values for ZRAM if available.
    ui_print "Patching built-in ZRAM fstab for Aries Kernel...";
    replace_line fstab.qcom "/dev/block/zram0                                    none            swap    defaults                                                                                            zramsize=533413200,zramstreams=4,notrim" "/dev/block/zram0                                    none            swap    defaults                                                                                            zramsize=536870912,zramstreams=2,notrim";
  fi;
fi;
# AOSP
if [ -f init.qcom.rc ]; then
  if [ "$SDK" -ge "24" ]; then
    ui_print "AOSP Nougat based ROM detected.";
    ui_print "Overlaying the default post-boot script...";
    replace_line init.qcom.rc "service post-boot-sh /system/bin/sh /aries-post_boot.sh" "service post-boot-sh /system/bin/sh /sbin/aries-post_boot.sh";
  elif [ "$SDK" -eq "23" ]; then
    ui_print "AOSP Marshmallow based ROM detected.";
    ui_print "Injecting ZRAM support...";
    backup_file init.qcom.rc;
    insert_line init.qcom.rc "zram0" after "symlink /sdcard /storage/sdcard0" "\n    # Setup ZRAM\n    write /sys/block/zram0/comp_algorithm lz4\n    write /sys/block/zram0/max_comp_streams 2\n";
    insert_line init.qcom.rc "swapon_all" after "mount_all ./fstab.qcom" "    swapon_all ./fstab.qcom";
    ui_print "Injecting post-boot script support...";
    append_file init.qcom.rc "aries-post_boot" init.script.patch;
  fi;
fi;
if [ -f fstab.qcom ]; then
  if [ -z "$(grep "zramsize" fstab.qcom)" ]; then
    # Add patch if ZRAM is not found in fstab.
    ui_print "Injecting ZRAM support fstab patch...";
    backup_file fstab.qcom;
    append_file fstab.qcom "zramsize" fstab.zram.patch;
  else
    # Do nothing, ZRAM value is set to optimal 512MB on AOSP Nougat.
    ui_print "Detected built-in ZRAM support...";
  fi;
fi;

# Fast Random
ui_print "Injecting frandom/erandom support...";
if [ -f file_contexts.bin ]; then
  # Nougat file_contexts binary can't be patched so simply.
  ui_print "File contexts is a binary file, skipping...";
elif [ -f file_contexts ]; then
  # Marshmallow file_contexts can be patched.
  ui_print "Patching file contexts...";
  backup_file file_contexts;
  insert_line file_contexts "frandom" after "/dev/urandom            u:object_r:urandom_device:s0" "/dev/frandom            u:object_r:frandom_device:s0\n/dev/erandom            u:object_r:erandom_device:s0"
fi;
if [ -f ueventd.rc ]; then
  ui_print "Patching ueventd devices...";
  backup_file ueventd.rc;
  insert_line ueventd.rc "frandom" after "/dev/urandom              0666   root       root" "/dev/frandom              0666   root       root\n/dev/erandom              0666   root       root"
fi;

# xPrivacy
# Thanks to @Shadowghoster & @laufersteppenwolf
# TODO: Change to native insert_line.
if [ "$SDK" -le "23" ]; then
  ui_print "Injecting xPrivacy support...";
  backup_file service_contexts;
  param=$(grep "xprivacy" service_contexts)
  if [ -z $param ]; then
    echo -ne "xprivacy453                                    u:object_r:system_server_service:s0\n" >> service_contexts
  fi
fi;

write_boot;
