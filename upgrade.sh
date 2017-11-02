#!/bin/sh
cd /home/vseobecne/ine/osrmv5/
version="5.13.0";
rm v* master.zip
rm -rf osrm-backend*
if [ 1 -eq 1 ]; then
	wget https://github.com/Project-OSRM/osrm-backend/archive/v$version.zip
	unzip -q v$version.zip
	mv osrm-backend-$version osrm-backend
else
	wget -O https://github.com/Project-OSRM/osrm-backend/archive/master.zip
	#wget -O master.zip https://github.com/Project-OSRM/osrm-backend/archive/fix/segment-end-points.zip # if you need a branch
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
