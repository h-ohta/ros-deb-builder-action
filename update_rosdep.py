#!/usr/bin/env python3
import argparse
import pathlib
import subprocess
import yaml

parser = argparse.ArgumentParser()
parser.add_argument("ros-distro")
parser.add_argument("base-dire")
parser.add_argument("rosdep-file")
args = parser.parse_args()
path = pathlib.Path(args.file)

command = ["colcon", "list", "-tn", "--base-paths", args.base]
process = subprocess.run(command, capture_output=True, text=True)

packages = yaml.safe_load(path.read_text()) if path.exists() else dict()
for ros_pkg in process.stdout.strip().split():
    deb_pkg = "ros-{}-{}".format(args.distro, ros_pkg.replace("_", "-"))
    packages[ros_pkg] = {"ubuntu": [deb_pkg]}

path.write_text(yaml.safe_dump(packages))
