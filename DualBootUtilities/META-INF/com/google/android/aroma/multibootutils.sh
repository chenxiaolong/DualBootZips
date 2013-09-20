#!/sbin/sh

# Common AROMA formatting functions
echo_bold() {
  echo -n "<b>"
  echo ${@}
  echo "</b>"
}

# Common mounting functions
BOOT="/dev/block/platform/msm_sdcc.1/by-name/boot"
SYSTEM="/dev/block/platform/msm_sdcc.1/by-name/system"
DATA="/dev/block/platform/msm_sdcc.1/by-name/userdata"
CACHE="/dev/block/platform/msm_sdcc.1/by-name/cache"

unmount_system() {
  umount /system &>/dev/null || true
}

mount_system() {
  unmount_system
  mount $SYSTEM /system
}

unmount_data() {
  umount /data &>/dev/null || true
}

mount_data() {
  unmount_data
  mount $DATA /data
}

unmount_cache() {
  umount /cache &>/dev/null || true
}

mount_cache() {
  unmount_cache
  mount $CACHE /cache
}

write_kernel() {
  dd if=$1 of=$BOOT || \
    { echo "Failed to write kernel" && return 1 }
}

read_kernel() {
  dd if=$BOOT of=$1 || \
    { echo "Failed to write kernel" && return 1 }
}

force_boot_primary() {
  mount_system
  local EXIT

  if [ ! -f /system/dual-kernels/primary.img ]; then
    echo "There's no kernel for the primary ROM. Did you remember to set the kernel in the Dual Boot Switcher app? You will need to flash a kernel for the primary ROM in order to boot it again."
    EXIT=1
  else
    if ! write_kernel /system/dual-kernels/primary.img; then
      echo "Failed to write kernel to boot partition!"
      EXIT=1
    else
      echo "Successfully switched to the primary ROM!"
      EXIT=0
    fi
  fi

  unmount_system
  exit $EXIT
}

force_boot_secondary() {
  mount_system
  local exit

  if [ ! -f /system/dual-kernels/secondary.img ]; then
    echo "There's no kernel for the secondary ROM. Is there a secondary ROM installed? You may need to reinstall the secondary ROM (or just flash the kernel for it)."
    EXIT=1
  else
    if ! write_kernel /system/dual-kernels/secondary.img; then
      echo "Failed to write kernel to boot partition!"
      EXIT=1
    else
      echo "Successfully switched to the secondary ROM!"
      EXIT=0
    fi
  fi

  unmount_system
  exit $EXIT
}

wipe_primary_cache() {
  mount_cache

  for i in $(ls /cache); do
    if [ "${i}" = "dual" ]; then
      echo "Skipping /cache/dual/"
      continue
    else
      echo "Deleting /cache/${i}"
      rm -rf /cache/${i}
    fi
  done

  unmount_cache
}

wipe_secondary_cache() {
  mount_cache
  echo "Deleting /cache/dual"
  rm -rf /cache/dual
  unmount_cache
}

wipe_primary_dalvik_cache() {
  mount_data
  echo "Deleting /data/dalvik-cache"
  rm -rf /data/dalvik-cache
  unmount_data
}

wipe_secondary_dalvik_cache() {
  mount_data
  echo "Deleting /data/dual/dalvik-cache"
  rm -rf /data/dual/dalvik-cache
  unmount_data
}

wipe_primary_system() {
  mount_system

  for i in $(ls /system); do
    if [ "${i}" = "dual" ]; then
      echo "Skipping /system/dual/"
      continue
    elif [ "${i}" = "dual-kernels" ]; then
      echo "Skipping /system/dual-kernels/"
      continue
    else
      echo "Deleting /system/${i}"
      rm -rf /system/${i}
    fi
  done

  echo "Deleting primary kernel"
  rm -f /system/dual-kernels/primary.img

  unmount_system
}

wipe_secondary_system() {
  mount_system
  echo "Deleting /system/dual"
  rm -rf /system/dual
  echo "Deleting secondary kernel"
  rm -rf /system/dual-kernels/secondary.img
  unmount_system
}

wipe_primary_data() {
  mount_data

  for i in $(ls /data); do
    if [ "${i}" = "dual" ]; then
      echo "Skipping /data/dual/"
      continue
    elif [ "${i}" = "media" ]; then
      echo "Skipping /data/media/"
      continue
    else
      echo "Deleting /data/${i}"
      rm -rf /data/${i}
    fi
  done

  unmount_data
}

wipe_secondary_data() {
  mount_data
  echo "Deleting /data/dual"
  rm -rf /data/dual
  unmount_data
}

save_last_kmsg() {
  echo "Copying /proc/last_kmsg to internal SD"
  cp /proc/last_kmsg /sdcard/ || exit 1
}

save_recovery_log() {
  echo "Copying /tmp/recovery.log to internal SD"
  cp /tmp/recovery.log /sdcard/ || exit 1
}

case $1 in
force-boot-primary)
  force_boot_primary
  ;;
force-boot-secondary)
  force_boot_secondary
  ;;
wipe-primary-cache)
  wipe_primary_cache
  ;;
wipe-secondary-cache)
  wipe_secondary_cache
  ;;
wipe-primary-dalvik-cache)
  wipe_primary_dalvik_cache
  ;;
wipe-secondary-dalvik-cache)
  wipe_secondary_dalvik_cache
  ;;
wipe-primary-system)
  wipe_primary_system
  ;;
wipe-secondary-system)
  wipe_secondary_system
  ;;
wipe-primary-data)
  wipe_primary_data
  ;;
wipe-secondary-data)
  wipe_secondary_data
  ;;
save-last-kmsg)
  save_last_kmsg
  ;;
save-recovery-log)
  save_recovery_log
  ;;
esac