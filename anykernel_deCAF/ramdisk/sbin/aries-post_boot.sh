#!/system/bin/sh
#
# Copyright - Ícaro Hoff <icarohoff@gmail.com>
# Copyright - RJ Murdok <rjmurdok@linux.com>
#
#              \
#              /\
#             /  \
#            /    \
#
BB=/sbin/busybox;

############################
# Kick-off
#
stop mpdecision # To avoid troubles...
echo "[Aries] Kicking-off post-boot script" | tee /dev/kmsg

############################
# RQ Stats
#
sleep 0.5
echo "[Aries] Disabling built-in RQ hotplug mechanism" | tee /dev/kmsg
echo "0" > /sys/devices/system/cpu/cpu0/rq-stats/hotplug_enable

############################
# Hotplugs
#
sleep 0.5
# MSM Hotplug:
echo "[Aries] Enabling MSM hotplug driver" | tee /dev/kmsg
echo "1" > /sys/module/msm_hotplug/msm_enabled

############################
# Governors
#
# Ondemand:
echo "[Aries] Tuning ondemand governor" | tee /dev/kmsg
echo "ondemand" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
sleep 0.25 # Wait for ondemand sysfs paths.
echo "95" > /sys/devices/system/cpu/cpufreq/ondemand/up_threshold
echo "50000" > /sys/devices/system/cpu/cpufreq/ondemand/sampling_rate
echo "1" > /sys/devices/system/cpu/cpufreq/ondemand/io_is_busy
echo "4" > /sys/devices/system/cpu/cpufreq/ondemand/sampling_down_factor
# Interactive:
echo "[Aries] Tuning interactive governor" | tee /dev/kmsg
echo "interactive" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
sleep 0.25 # Wait for interactive sysfs paths.
echo "20000 1400000:40000 1700000:20000" > /sys/devices/system/cpu/cpufreq/interactive/above_hispeed_delay
echo "70" > /sys/devices/system/cpu/cpufreq/interactive/go_hispeed_load
echo "1190400" > /sys/devices/system/cpu/cpufreq/interactive/hispeed_freq
echo "1" > /sys/devices/system/cpu/cpufreq/interactive/io_is_busy
echo "89 1300000:45 1500000:65 1700000:80 1800000:98" > /sys/devices/system/cpu/cpufreq/interactive/target_loads
echo "40000" > /sys/devices/system/cpu/cpufreq/interactive/min_sample_time
echo "30000" > /sys/devices/system/cpu/cpufreq/interactive/timer_rate
echo "-1" > /sys/devices/system/cpu/cpufreq/interactive/timer_slack
echo "100000" > /sys/devices/system/cpu/cpufreq/interactive/sampling_down_factor
# Impulse:
echo "impulse" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
sleep 0.25 # Wait for impulse sysfs paths.
echo "[Aries] Tuning impulse governor" | tee /dev/kmsg
echo "19000 1400000:39000 1700000:19000 2100000:79000" > /sys/devices/system/cpu/cpufreq/impulse/above_hispeed_delay
echo "95" > /sys/devices/system/cpu/cpufreq/impulse/go_hispeed_load
echo "1728000" > /sys/devices/system/cpu/cpufreq/impulse/hispeed_freq
echo "1" > /sys/devices/system/cpu/cpufreq/impulse/io_is_busy
echo "85 1500000:90 1800000:70 2100000:95" > /sys/devices/system/cpu/cpufreq/impulse/target_loads
echo "1" > /sys/devices/system/cpu/cpufreq/impulse/powersave_bias
echo "79000" > /sys/devices/system/cpu/cpufreq/impulse/max_freq_hysteresis
echo "19000" > /sys/devices/system/cpu/cpufreq/impulse/min_sample_time
echo "20000" > /sys/devices/system/cpu/cpufreq/impulse/timer_rate

############################
# Scheduler
#
sleep 0.25
echo "[Aries] Disabling buggy notify on migrate" | tee /dev/kmsg
echo "0" > /dev/cpuctl/cpu.notify_on_migrate

############################
# MSM Limiter
#
sleep 0.5
echo "[Aries] Initializing MSM limiter" | tee /dev/kmsg
echo "ondemand" > /sys/kernel/msm_limiter/scaling_governor
echo "2265600" > /sys/kernel/msm_limiter/resume_max_freq
echo "1" > /sys/kernel/msm_limiter/debug_mask
echo "1" > /sys/kernel/msm_limiter/freq_control

############################
# CPU Input Boost
#
sleep 0.5
echo "[Aries] Burning CPU input boost values" | tee /dev/kmsg
echo "1190400 1497600" > /sys/kernel/cpu_input_boost/ib_freqs
echo "1400" > /sys/kernel/cpu_input_boost/ib_duration_ms
echo "[Aries] Enabling CPU input boost driver" | tee /dev/kmsg
echo "1" > /sys/kernel/cpu_input_boost/enabled

############################
# GPU
#
sleep 0.55
echo "[Aries] Tweaking CPU BW monitor governor" | tee /dev/kmsg
echo "cpubw_hwmon" > /sys/class/devfreq/qcom,cpubw.42/governor
echo "381 762 2342 6103 7102" > /sys/class/devfreq/qcom,cpubw.42/cpubw_hwmon/mbps_zones
echo "4" > /sys/class/devfreq/qcom,cpubw.42/cpubw_hwmon/sample_ms
echo "34" > /sys/class/devfreq/qcom,cpubw.42/cpubw_hwmon/io_percent
echo "95" > /sys/class/devfreq/qcom,cpubw.42/cpubw_hwmon/bw_step
echo "20" > /sys/class/devfreq/qcom,cpubw.42/cpubw_hwmon/hist_memory
echo "10" > /sys/class/devfreq/qcom,cpubw.42/cpubw_hwmon/hyst_length
echo "0" > /sys/class/devfreq/qcom,cpubw.42/cpubw_hwmon/low_power_ceil_mbps
echo "34" > /sys/class/devfreq/qcom,cpubw.42/cpubw_hwmon/low_power_io_percent
echo "20" > /sys/class/devfreq/qcom,cpubw.42/cpubw_hwmon/low_power_delay
echo "0" > /sys/class/devfreq/qcom,cpubw.42/cpubw_hwmon/guard_band_mbps
echo "250" > /sys/class/devfreq/qcom,cpubw.42/cpubw_hwmon/up_scale
echo "400" > /sys/class/devfreq/qcom,cpubw.42/cpubw_hwmon/idle_mbps
echo "250" > /sys/class/devfreq/qcom,cpubw.42/cpubw_hwmon/min_mbps

############################
# Scheduler/Read Ahead
#
sleep 0.25
echo "[Aries] Setting zen as default scheduler" | tee /dev/kmsg
echo "zen" > /sys/block/mmcblk0/queue/scheduler
setprop sys.io.scheduler "zen"
echo "[Aries] Setting 1024kB as read ahead" | tee /dev/kmsg
echo "1024" > /sys/block/mmcblk0/bdi/read_ahead_kb

############################
# Adreno Idler
#
sleep 0.25
echo "[Aries] Tweaking adreno idler parameters" | tee /dev/kmsg
echo "2500" > /sys/module/adreno_idler/parameters/adreno_idler_idleworkload
echo "100" > /sys/module/adreno_idler/parameters/adreno_idler_idlewait
echo "50" > /sys/module/adreno_idler/parameters/adreno_idler_downdifferential
echo "[Aries] Disabling adreno idler driver" | tee /dev/kmsg
echo "0" > /sys/module/adreno_idler/parameters/adreno_idler_active

############################
# Simple GPU Algorithm
#
sleep 0.25
echo "[Aries] Tweaking simple gpu algorithm parameters" | tee /dev/kmsg
echo "2" > /sys/module/simple_gpu_algorithm/parameters/simple_laziness
echo "7000" > /sys/module/simple_gpu_algorithm/parameters/simple_ramp_threshold
echo "[Aries] Enabling simple gpu algorithm driver" | tee /dev/kmsg
echo "1" > /sys/module/simple_gpu_algorithm/parameters/simple_gpu_activate

############################
# Random
#
sleep 0.25
echo "[Aries] Optimizing random wakeup thresholds" | tee /dev/kmsg
echo "512" > /proc/sys/kernel/random/read_wakeup_threshold
echo "256" > /proc/sys/kernel/random/write_wakeup_threshold

############################
# VM
#
sleep 0.5
echo "[Aries] Optimizing virtual machine values" | tee /dev/kmsg
echo "200" > /proc/sys/vm/dirty_expire_centisecs
echo "20" > /proc/sys/vm/dirty_ratio
echo "5" > /proc/sys/vm/dirty_background_ratio
echo "50" > /proc/sys/vm/swappiness
echo "100" > /proc/sys/vm/vfs_cache_pressure

############################
# Process Reclaim
#
sleep 0.25
echo "[Aries] Empowering process reclaim" | tee /dev/kmsg
echo "1" > /sys/module/process_reclaim/parameters/enable_process_reclaim
echo "80" > /sys/module/process_reclaim/parameters/pressure_max

############################
# LMK
#
sleep 0.25
echo "[Aries] Setting custom LMK values" | tee /dev/kmsg
echo "18432,23040,24576,28672,31744,34816" > /sys/module/lowmemorykiller/parameters/minfree
echo "48" > /sys/module/lowmemorykiller/parameters/cost
echo "73728" > /sys/module/lowmemorykiller/parameters/vmpressure_file_min
echo "1" > /sys/module/lowmemorykiller/parameters/enable_adaptive_lmk
echo "85" > /sys/module/lowmemorykiller/parameters/vm_pressure_adaptive_start

############################
# HID Keyboard
#
sleep 0.25
echo "[Aries] Disabling USB keyboard support" | tee /dev/kmsg
echo "0" > /sys/module/g_android/parameters/usb_keyboard

############################
# Modem SPS
#
sleep 0.25
echo "[Aries] Enabling modem data suspend" | tee /dev/kmsg
echo "1" > /sys/module/sps_bam/parameters/allow_suspend

############################
# Debugging
#
sleep 0.25
echo "[Aries] Disabling debug masks" | tee /dev/kmsg
echo "0" > /sys/module/kernel/parameters/initcall_debug;
echo "0" > /sys/module/alarm_dev/parameters/debug_mask;
echo "0" > /sys/module/binder/parameters/debug_mask;
echo "0" > /sys/module/xt_qtaguid/parameters/debug_mask;
echo "0" > /sys/devices/fe12f000.slim/debug_mask
echo "0" > /sys/module/smd/parameters/debug_mask
echo "0" > /sys/module/smem/parameters/debug_mask
echo "0" > /sys/module/rpm_regulator_smd/parameters/debug_mask
echo "0" > /sys/module/ipc_router/parameters/debug_mask
echo "0" > /sys/module/event_timer/parameters/debug_mask
echo "0" > /sys/module/smp2p/parameters/debug_mask
echo "0" > /sys/module/rpm_smd/parameters/debug_mask
echo "0" > /sys/module/smd_pkt/parameters/debug_mask
echo "0" > /sys/module/qpnp_regulator/parameters/debug_mask
echo "0" > /sys/module/msm_show_resume_irq/parameters/debug_mask
echo "0" > /sys/module/mpm_of/parameters/debug_mask
echo "0" > /sys/module/msm_pm/parameters/debug_mask
echo "0" > /sys/module/spm_v2/parameters/debug_mask
echo "0" > /sys/module/lpm_levels/parameters/debug_mask
echo "0" > /sys/module/ipc_router_smd_xprt/parameters/debug_mask

############################
# Done!
#
echo "[Aries] Exiting post-boot script" | tee /dev/kmsg
