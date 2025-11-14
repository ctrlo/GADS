#!/bin/sh

set -e

version=$(sed -n "s/.*\$VERSION *= *['\"]*\([^'\"]*\).*/\1/p" ./lib/GADS.pm)

echo "Building scripts for GADS version $version"

yarn --frozen-lockfile
npx update-browserslist-db@latest
NODE_ENV=production yarn webpack
git checkout ./public/js/fengari-web.js

echo "Building GADS version $version"

mkdir -p GADS-$version/srv/GADS
mkdir -p GADS-$version/DEBIAN

echo "Copying files..."
cp -r bin environments lib public share views config.yml-example GADS-$version/srv/GADS/
sed "s/%version%/$version/g" dpkg/control > GADS-$version/DEBIAN/control
if [ -f dpkg/postrm ]; then
    cp dpkg/postrm GADS-$version/DEBIAN/postrm
fi
if [ -f dpkg/postinst ]; then
    cp dpkg/postinst GADS-$version/DEBIAN/postinst
fi

echo "Building package..."
cd GADS-$version
dpkg-deb --build . ../GADS-$version.deb

echo "Package built: GADS-$version.deb"

echo "Cleaning up..."
cd ..
rm -rf GADS-$version

echo "Done."
