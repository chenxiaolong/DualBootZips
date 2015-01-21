#!/bin/bash

cd "$(dirname ${0})"

UPDATE_BINARY=""

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
unzip aroma.zip META-INF/com/google/android/update-binary
zip DualBootUtilities-${VERSION}.zip \
    META-INF/com/google/android/update-binary

rm -rf META-INF/
