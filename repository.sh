#!/bin/sh
# SPDX-License-Identifier: BSD-3-Clause

set -ex

RELEASE_DIR="dists/$DEB_DISTRO"
PACKAGE_DIR="dists/$DEB_DISTRO/universe/binary-amd64"
for file in $(ls /home/runner/apt_repo/*.deb); do mv "$file" "$PACKAGE_DIR"; done

echo "Suite: $DEB_DISTRO" > "$RELEASE_DIR/Release"
echo "Components: universe" >> "$RELEASE_DIR/Release"
echo "Architectures: amd64" >> "$RELEASE_DIR/Release"

apt-ftparchive packages "$PACKAGE_DIR" > "$PACKAGE_DIR/Packages"
apt-ftparchive release "$RELEASE_DIR" >> "$RELEASE_DIR/Release"
