#!/usr/bin/env python3
import argparse
import pathlib
import subprocess
import yaml

parser = argparse.ArgumentParser()
parser.add_argument("repos_config")
args = parser.parse_args()

path = pathlib.Path(args.repos_config)
data = yaml.safe_load(path.read_text())

command = "colcon list -t --base-paths src".split()
process = subprocess.run(command, capture_output=True, text=True)

for line in process.stdout.strip().split("\n"):
    name, path = line.split()[0:2]
    if data["packages"].get(name, {}).get("ignore", False):
        path = pathlib.Path(path)
        path.joinpath("COLCON_IGNORE").write_text("")
