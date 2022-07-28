#!/usr/bin/env python

import json
import sys


# Must provide a cutoff version, e.g. 'v6.0.4'
starting_version = sys.argv[1]
version_major = int(starting_version[1])
version_patch = int(starting_version[5])

# Read JSON output from generate_start_matrix.py
with open('releases.json', 'r', encoding='utf-8') as releases_file:
    releases_list = json.load(releases_file)

# Trim list to only releases from specified version onwards
trimmed_releases = [release for release in releases_list if
                    (int(release['name'][1]) == version_major and
                     int(release['name'][5]) >= version_patch) or
                    int(release['name'][1]) > version_major]
trimmed_releases.append({'name': 'release/v7.0.x'})
for rel in trimmed_releases:
    if rel['name'] == 'v7.0.0-rc0':
        trimmed_releases.remove(rel)

# Set upgrade versions to target for each release
matrix = {release['name']: [] for release in trimmed_releases}
matrix['release/v7.0.x'] = []

# This skips v7.0.0-rc0
for start_version, _ in matrix.items():
    matrix[start_version] = [
        release['name']
        for release in trimmed_releases
        if int(release['name'][-5]) > int(start_version[-5])
        ]

# Assemble matrix include section:
includes = []
for version, upgrades in matrix.items():
    for upgrade in upgrades:
        includes.append({'gaia_version': version, 'upgrade_version': upgrade})
upgrade_json = json.dumps({'include': includes})
print(upgrade_json)
