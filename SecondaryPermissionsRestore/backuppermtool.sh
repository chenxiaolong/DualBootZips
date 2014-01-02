#!/sbin/sh
#
# Copyright (c) 2014 Xiao-Long Chen <chenxiaolong@cxl.epac.to>
#
# Back up and restore permissions of the secondary ROM

case ${1} in
backup)
  cd /system
  if [ -d dual ]; then
    /tmp/getfacl -R dual > /tmp/dual.acl.txt
    /tmp/getfattr -R -n security.selinux dual > /tmp/dual.attr.txt
  fi
  ;;

restore)
  cd /system
  if [ -d dual ]; then
    /tmp/setfacl --restore=/tmp/dual.acl.txt
    /tmp/setfattr --restore=/tmp/dual.attr.txt
  fi
  ;;

*)
  echo "Usage: ${0} [backup|restore]"
  exit 1
  ;;
esac
