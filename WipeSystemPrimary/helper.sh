#!/sbin/sh

wipe_primary_system() {
  for i in $(ls /system); do
    if [ "${i}" = "dual" ]; then
      echo "Skipping /system/dual/"
      continue
    elif [ "${i}" = "dual-kernels" ]; then
      echo "Skipping /system/dual-kernels/"
      continue
    else
      rm -rf /system/${i}
    fi
  done
}

case $1 in
wipe-primary-system)
  wipe_primary_system
  ;;
esac
