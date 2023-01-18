#!/bin/sh
# SPDX-License-Identifier: BSD-3-Clause

set -ex

if debian-distro-info --all | grep -q "$DEB_DISTRO"; then
  DISTRIBUTION=debian
elif ubuntu-distro-info --all | grep -q "$DEB_DISTRO"; then
  DISTRIBUTION=ubuntu
else
  echo "Unknown DEB_DISTRO: $DEB_DISTRO"
  exit 1
fi

case $ROS_DISTRO in
  debian)
    ;;
  boxturtle|cturtle|diamondback|electric|fuerte|groovy|hydro|indigo|jade|kinetic|lunar)
    echo "Unsupported ROS 1 version: $ROS_DISTRO"
    exit 1
    ;;
  melodic|noetic)
    BLOOM=ros
    ROS_DEB="$ROS_DISTRO-"
    curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /home/runner/ros-archive-keyring.gpg
    set -- --extra-repository="deb http://packages.ros.org/ros/ubuntu $DEB_DISTRO main" --extra-repository-key=/home/runner/ros-archive-keyring.gpg "$@"
    ;;
  *)
    # assume ROS 2 so we don't have to list versions
    BLOOM=ros
    ROS_DEB="$ROS_DISTRO-"
    curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /home/runner/ros-archive-keyring.gpg
    set -- --extra-repository="deb http://packages.ros.org/ros2/ubuntu $DEB_DISTRO main" --extra-repository-key=/home/runner/ros-archive-keyring.gpg "$@"
    ;;
esac

# make output directory
mkdir /home/runner/apt_repo

echo "Add unreleased packages to rosdep"

git checkout $TARGET_BRANCH

ROSDEP_FILE="$GITHUB_WORKSPACE/rosdep/$ROS_DISTRO.yaml"
python3 $GITHUB_ACTION_PATH/update_rosdep.py "$ROS_DISTRO" src "$ROSDEP_FILE"

sudo rosdep init
echo "yaml file://$ROSDEP_FILE $ROS_DISTRO" | sudo tee /etc/ros/rosdep/sources.list.d/1-local.list
printf "%s" "$ROSDEP_SOURCE" | sudo tee /etc/ros/rosdep/sources.list.d/2-remote.list
rosdep update

# skip packages without version change
python3 $GITHUB_ACTION_PATH/select_rospkg.py src "dists/$DEB_DISTRO"

echo "Run sbuild"

# Don't build tests
export DEB_BUILD_OPTIONS=nocheck

TOTAL="$(colcon list -tn | wc -l)"
COUNT=1

# TODO: use colcon list -tp in future
for PKG_PATH in $(colcon list -tp); do
  echo "::group::Building $COUNT/$TOTAL: $PKG_PATH"
  test -f "$PKG_PATH/CATKIN_IGNORE" && echo "Skipped" && continue
  test -f "$PKG_PATH/COLCON_IGNORE" && echo "Skipped" && continue
  (
  cd "$PKG_PATH"

  bloom-generate "${BLOOM}debian" --os-name="$DISTRIBUTION" --os-version="$DEB_DISTRO" --ros-distro="$ROS_DISTRO"

  # Set the version
  sed -i "1 s/([^)]*)/($(python3 $GITHUB_ACTION_PATH/version.py package.xml)-$(date +%Y.%m.%d.%H.%M))/" debian/changelog

  # https://github.com/ros-infrastructure/bloom/pull/643
  echo 11 > debian/compat

  # dpkg-source-opts: no need for upstream.tar.gz
  sbuild --chroot-mode=unshare --no-clean-source --no-run-lintian \
    --dpkg-source-opts="-Zgzip -z1 --format=1.0 -sn" --build-dir=/home/runner/apt_repo \
    --extra-package=/home/runner/apt_repo "$@"
  )
  COUNT=$((COUNT+1))
  echo "::endgroup::"
done

ccache -sv
