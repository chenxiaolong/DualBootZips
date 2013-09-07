#!/sbin/sh

PROP=/tmp/dualboot.prop

force_boot_secondary() {
  if [ ! -f /system/dual-kernels/secondary.img ]; then
    echo 'ro.dualboot.error=1' > $PROP
  else
    echo 'ro.dualboot.error=0' > $PROP
    dd if=/system/dual-kernels/secondary.img \
       of=/dev/block/platform/msm_sdcc.1/by-name/boot
  fi
}

case $1 in
force-boot-secondary)
  force_boot_secondary
  ;;
esac
