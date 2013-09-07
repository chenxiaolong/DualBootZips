#!/sbin/sh

enable_dual() {
  touch /system/.dualboot
}

case $1 in
enable)
  enable_dual
  ;;
esac
