#!/usr/bin/env python3
import argparse
import pathlib
import subprocess
import yaml

parser = argparse.ArgumentParser()
parser.add_argument("ros_distro")
parser.add_argument("pkg_source")
parser.add_argument("rosdep_file")
args = parser.parse_args()
path = pathlib.Path(args.rosdep_file)

command = ["colcon", "list", "-tn", "--base-paths", args.pkg_source]
process = subprocess.run(command, capture_output=True, text=True)

packages = yaml.safe_load(path.read_text()) if path.exists() else dict()
for ros_pkg in process.stdout.strip().split():
    deb_pkg = "ros-{}-{}".format(args.ros_distro, ros_pkg.replace("_", "-"))
    packages[ros_pkg] = {"ubuntu": [deb_pkg]}

path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(yaml.safe_dump(packages))
