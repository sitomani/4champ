#/bin/sh

git submodule update --init --recursive
cd uade-ios && ./build_ios_framework.sh && cd ..
cd openmpt && ./iOS_build.sh && cd ..
