import argparse
import pathlib
import subprocess
import xml.etree.ElementTree as ET

def collect_versions(path):
  versions = {}
  with open(path) as fp:
    package = None
    for line in fp:
      line = line.strip()
      if line.startswith("Package:") and not line.endswith("-dbgsym"):
        package = "_".join(line[8:].strip().split("-")[2:])
      if line.startswith("Version:") and package:
        versions[package] = line[8:].strip().split("-")[0]
        package = None
  return versions

def check_version(path, versions):
  path = pathlib.Path(path)
  root = ET.parse(path.joinpath("package.xml"))
  name = root.find("name").text
  curr = root.find("version").text
  prev = versions[name]
  if prev != curr:
    print(f"{name}: {prev} => {curr}")
  else:
    path.joinpath("COLCON_IGNORE").write_text("")

parser = argparse.ArgumentParser()
parser.add_argument("packages", default="Packages")
parser.add_argument("workspace", default=".")
args = parser.parse_args()

versions = collect_versions(args.packages)

command = ["colcon", "list", "-tp", "--base-paths", args.workspace]
process = subprocess.run(command, capture_output=True, text=True)
for line in process.stdout.strip().split():
  check_version(line, versions)
