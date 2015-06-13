#!/bin/bash

cd "$(dirname "${0}")"

rm -rf META-INF/

pushd DualBootUtilities/template/
version=$(sed -n 's/^.*ini_set(.*\"rom_version\",.*\"\(.*\)\".*$/\1/p' \
              META-INF/com/google/android/aroma-config.in)
popd

zip_file="$(readlink -f DualBootUtilities-"${version}".zip)"

pushd DualBootUtilities/
rm -f "${zip_file}"
zip -r "${zip_file}" ./*
popd

if [ ! -f aroma.zip ]; then
    wget -O aroma.zip 'http://forum.xda-developers.com/devdb/project/dl/?id=286&task=get'
fi

aroma="$(readlink -f aroma.zip)"

tempdir="$(mktemp -d)"
mkdir -p "${tempdir}/template/"
pushd "${tempdir}/template/"
unzip "${aroma}" META-INF/com/google/android/update-binary
cd ..
zip "${zip_file}" template/META-INF/com/google/android/update-binary
popd
rm -rf "${tempdir}"
