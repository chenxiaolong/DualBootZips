#!/sbin/sh

disable_dual() {
  rm -f /system/.dualboot
}

case $1 in
disable)
  disable_dual
  ;;
esac
