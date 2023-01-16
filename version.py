import argparse
import xml.etree.ElementTree as ET

parser = argparse.ArgumentParser()
parser.add_argument("path")
args = parser.parse_args()
root = ET.parse(args.path)
print(root.find("version").text)
