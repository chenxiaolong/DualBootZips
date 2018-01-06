#!/bin/bash
version=$(sed -nr 's/^VERSION=(.+)/\1/p' META-INF/com/google/android/update-binary)
rm -f "GetLogs-${version}.zip"
zip -r "GetLogs-${version}.zip" META-INF
