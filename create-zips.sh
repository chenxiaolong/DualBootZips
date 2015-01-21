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

#for i in $(find . -maxdepth 1 -type d ! -name .git ! -name . ! -name META-INF); do
for i in DualBootDisable; do
  i=$(basename ${i})
  cd ${i}
  rm -f ../${i}.zip
  zip -r ../${i}.zip *
  cd ..
  zip ${i}.zip META-INF/com/google/android/update-binary
done

rm -rf META-INF/

cd DualBootUtilities
VERSION=$(cat META-INF/com/google/android/aroma-config | \
            sed -n 's/^.*ini_set(.*\"rom_version\",.*\"\(.*\)\".*$/\1/p')
rm -f ../DualBootUtilities-${VERSION}.zip
zip -r ../DualBootUtilities-${VERSION}.zip *
cd ..

if [ ! -f aroma.zip ]; then
  wget -O aroma.zip 'http://forum.xda-developers.com/devdb/project/dl/?id=286&task=get'
fi
unzip aroma.zip META-INF/com/google/android/update-binary{,-installer}
zip DualBootUtilities-${VERSION}.zip \
    META-INF/com/google/android/update-binary{,-installer}

rm -rf META-INF/
