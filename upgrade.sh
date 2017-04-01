#!/bin/sh
# upgrade osrm to new version, run in your working directory
version="5.6.0";
rm v* master.zip
rm -rf osrm-backend*
if [ 0 -eq 1 ]; then
    wget https://github.com/Project-OSRM/osrm-backend/archive/v$version.zip
    unzip -q v$version.zip
    mv osrm-backend-$version osrm-backend
else
    #wget -O https://github.com/Project-OSRM/osrm-backend/archive/master.zip
    wget -O master.zip https://github.com/Project-OSRM/osrm-backend/archive/fix/segment-end-points.zip
    rm -r tmp/; mkdir tmp; unzip -q master.zip -d tmp/
    mv tmp/* osrm-backend
fi

cd osrm-backend
mkdir -p build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build .
cd ../../
echo " ";
echo "cd /home/vseobecne/ine/osrmv5/osrm-backend/build; cmake --build . --target install";
echo " ";
cp -pr osrm-backend/profiles/lib .
