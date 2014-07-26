#!/sbin/sh

# Common mounting functions
BOOT="/dev/block/platform/msm_sdcc.1/by-name/boot"
SYSTEM="/dev/block/platform/msm_sdcc.1/by-name/system"
CACHE="/dev/block/platform/msm_sdcc.1/by-name/cache"
DATA="/dev/block/platform/msm_sdcc.1/by-name/userdata"

unmount_system() {
  umount /system &>/dev/null || true
}

mount_system() {
  unmount_system
  mount $SYSTEM /system
}

unmount_cache() {
  umount /cache &>/dev/null || true
}

mount_cache() {
  unmount_cache
  mount $CACHE /cache
}

unmount_data() {
  umount /data &>/dev/null || true
}

mount_data() {
  unmount_data
  mount $DATA /data
}

write_kernel() {
  dd if=$1 of=$BOOT || {
    echo "Failed to write kernel" && return 1
  }
}

read_kernel() {
  dd if=$BOOT of=$1 || {
    echo "Failed to write kernel" && return 1
  }
}

switch_to() {
  mount_data
  mount_system
  local EXIT

  local KERNEL

  KERNEL=/data/media/0/MultiKernels/$1.img
  if [ ! -f $KERNEL ]; then
    KERNEL=/system/dual-kernels/$1.img
  fi
  if [ ! -f $KERNEL ]; then
    echo "There's no kernel for the $1 ROM. Did you remember to set the kernel in the Dual Boot Switcher app? You will need to flash a kernel for the $1 ROM in order to boot it again."
    EXIT=1
  elif ! write_kernel $KERNEL; then
    echo "Failed to write kernel to boot partition."
    EXIT=1
  else
    echo "Successfully switched to the $1 ROM."
    EXIT=0
  fi

  unmount_data
  unmount_system
  exit $EXIT
}

wipe_system() {
  mount_system
  mount_cache
  mount_data

  case $1 in
  primary)
    for i in $(ls /system); do
      case $i in
      dual)
        echo "Skipping /system/dual/"
        continue
        ;;
      dual-kernels)
        echo "Skipping /system/dual-kernels/"
        continue
        ;;
      multi-slot-*)
        echo "Skipping /system/$i/"
        continue
        ;;
      *)
        echo "Deleting /system/$i/"
        rm -rf /system/$i
        ;;
      esac
    done

    echo "Deleting primary kernel"
    rm -f /system/dual-kernels/primary.img
    rm -f /data/media/0/MultiKernels/primary.img
    ;;

  secondary)
    echo "Deleting /system/dual/"
    rm -rf /system/dual
    echo "Deleting secondary kernel"
    rm -f /system/dual-kernels/secondary.img
    rm -f /data/media/0/MultiKernels/secondary.img
    ;;

  multi-slot-*)
    echo "Deleting /cache/$1/"
    rm -rf /cache/$1
    echo "Deleting $1 kernel"
    rm -f /system/dual-kernels/$1.img
    rm -f /data/media/0/MultiKernels/$1.img
  esac

  unmount_system
  unmount_cache
  unmount_data
}

wipe_cache() {
  mount_system
  mount_cache

  case $1 in
  primary)
    for i in $(ls /cache); do
      case $i in
      dual)
        echo "Skipping /cache/dual/"
        continue
        ;;
      multi-slot-*)
        echo "Skipping /cache/$i/"
        continue
        ;;
      *)
        echo "Deleting /cache/$i/"
        rm -rf /cache/$i
        ;;
      esac
    done
    ;;

  secondary)
    echo "Deleting /cache/dual/"
    rm -rf /cache/dual
    ;;

  multi-slot-*)
    echo "Deleting /system/$1/"
    rm -rf /system/$1
    ;;
  esac

  unmount_system
  unmount_cache
}

wipe_data() {
  mount_data

  case $1 in
  primary)
    for i in $(ls /data); do
      case $i in
      media)
        echo "Skipping /data/media/"
        continue
        ;;
      dual)
        echo "Skipping /data/dual/"
        continue
        ;;
      multi-slot-*)
        echo "Skipping /data/$i/"
        continue
        ;;
      *)
        echo "Deleting /data/$i/"
        rm -rf /data/$i
        ;;
      esac
    done
    ;;

  secondary)
    echo "Deleting /data/dual/"
    rm -rf /data/dual
    ;;

  multi-slot-*)
    echo "Deleting /data/$1/"
    rm -rf /data/$1
    ;;
  esac

  unmount_data
}

wipe_dalvik_cache() {
  mount_data

  case $1 in
  primary)
    echo "Deleting /data/dalvik-cache/"
    rm -rf /data/dalvik-cache
    echo "Deleting /cache/dalvik-cache/"
    rm -rf /cache/dalvik-cache
    ;;

  secondary)
    echo "Deleting /data/dual/dalvik-cache/"
    rm -rf /data/dual/dalvik-cache
    echo "Deleting /cache/dual/dalvik-cache/"
    rm -rf /cache/dual/dalvik-cache
    ;;

  multi-slot-*)
    echo "Deleting /data/$1/dalvik-cache/"
    rm -rf /data/$1/dalvik-cache
    echo "Deleting /system/$1/cache/dalvik-cache/"
    rm -rf /system/$1/cache/dalvik-cache
    ;;
  esac

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
switch-to-*)
  switch_to ${1#switch-to-}
  ;;
wipe-system-*)
  wipe_system ${1#wipe-system-}
  ;;
wipe-cache-*)
  wipe_cache ${1#wipe-cache-}
  ;;
wipe-data-*)
  wipe_data ${1#wipe-data-}
  ;;
wipe-dalvik-cache-*)
  wipe_dalvik_cache ${1#wipe-dalvik-cache-}
  ;;
wipe-caches-*)
  wipe_cache ${1#wipe-caches-}
  wipe_dalvik_cache ${1#wipe-caches-}
  ;;
wipe-all-*)
  wipe_system ${1#wipe-all-}
  wipe_cache ${1#wipe-all-}
  wipe_data ${1#wipe-all-}
  wipe_dalvik_cache ${1#wipe-all-}
  ;;
save-last-kmsg)
  save_last_kmsg
  ;;
save-recovery-log)
  save_recovery_log
  ;;
esac
