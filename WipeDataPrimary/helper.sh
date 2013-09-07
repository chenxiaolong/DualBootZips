#!/sbin/sh

wipe_primary_data() {
  for i in $(ls /data); do
    if [ "${i}" = "dual" ]; then
      echo "Skipping /data/dual/"
      continue
    elif [ "${i}" = "media" ]; then
      echo "Skipping /data/media/"
      continue
    else
      rm -rf /data/${i}
    fi
  done
}

case $1 in
wipe-primary-data)
  wipe_primary_data
  ;;
esac
