#!/bin/bash

cd "$(dirname ${0})"

UPDATE_BINARY=""
ROM_ZIP=""

usage() {
  echo "Usage: ${0} -z [any ROM zip file]"
  exit 1
}

if [ ${#} -eq 0 ]; then
  usage
fi

while [ ${#} -gt 0 ]; do
  case ${1} in
  -z)
    shift
    ROM_ZIP=${1}
    shift
    ;;
  -h)
    usage
    ;;
  *)
    echo "Unrecognized argument: ${1}"
    echo
    usage
    ;;
  esac
done

if [ ! -f "${ROM_ZIP}" ]; then
  echo "${ROM_ZIP} does not exist!"
  exit 1
fi

rm -rf META-INF/
unzip "${ROM_ZIP}" META-INF/com/google/android/update-binary

for i in $(find . -maxdepth 1 -type d ! -name .git ! -name . ! -name META-INF); do
  i=$(basename ${i})
  cd ${i}
  zip -r ../${i}.zip *
  cd ..
  zip ${i}.zip META-INF/com/google/android/update-binary
done

rm -rf META-INF/
