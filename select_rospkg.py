import argparse
import collections
import pathlib
import subprocess
import xml.etree.ElementTree as ET

def collect_versions(dists):
  versions = collections.defaultdict(set)
  for path in dists.glob("**/*.deb"):
    parts = path.stem.split("_")
    package = "_".join(parts[0].split("-")[2:])
    version = parts[1].split("-")[0]
    versions[package].add(version)
  return versions

def check_version(path, versions):
  path = pathlib.Path(path)
  root = ET.parse(path.joinpath("package.xml"))
  package = root.find("name").text
  version = root.find("version").text
  skipped = version in versions[package]
  if skipped:
    path.joinpath("COLCON_IGNORE").write_text("")

parser = argparse.ArgumentParser()
parser.add_argument("pkg_source")
parser.add_argument("deb_source")
args = parser.parse_args()
path = pathlib.Path(args.deb_source)

versions = collect_versions(path)

command = ["colcon", "list", "-tp", "--base-paths", args.pkg_source]
process = subprocess.run(command, capture_output=True, text=True)
for line in process.stdout.strip().split():
  check_version(line, versions)
