#!/sbin/sh

wipe_primary_cache() {
  for i in $(ls /cache); do
    if [ "${i}" = "dual" ]; then
      echo "Skipping /cache/dual/"
      continue
    else
      rm -rf /cache/${i}
    fi
  done
}

case $1 in
wipe-primary-cache)
  wipe_primary_cache
  ;;
esac
