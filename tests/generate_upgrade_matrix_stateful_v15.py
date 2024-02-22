#!/usr/bin/env python

import json
import sys
import re

SKIP_STARTING_VERSIONS = ['v14.0.0','v15.0.0-rc0','v15.0.0-rc1','v15.0.0-rc2','v15.0.0-rc3','v15.0.0']
SKIP_TARGET_VERSIONS = ['v15.0.0-rc0','v15.0.0-rc1']

# Must provide a cutoff version, e.g. 'v6.0.4'
starting_version = sys.argv[1].split('.')
version_major = int(starting_version[0][1:])
version_minor = int(starting_version[1])
version_patch = int(starting_version[2])

# Read JSON output from generate_start_matrix.py
with open('releases.json', 'r', encoding='utf-8') as releases_file:
    releases_list = json.load(releases_file)

# Filter names that do not comply to `vA.B.C` format (-rcX suffix is fine)
version_pattern = r'v\d+.\d+.\d+(-rc\d*)?'
release_names = [ release['name'] for release in releases_list if re.fullmatch(version_pattern, release['name']) ]

releases = []
rc_releases = []
for name in release_names:
    components = name.split('.')
    if ' ' in components[2]:
        continue
    # Trim list to only releases from specified version onwards
    if (int(components[0][1:]) == version_major and int(components[2].split('-')[0]) >= version_patch) or \
        int(components[0][1:]) > version_major:
        if 'rc' in components[2]:
            rc_releases.append(name)
        else:
            releases.append(name)

# Remove all rcs from the list if there is a final release available
for rc in rc_releases:
    if rc.split('-')[0] not in releases:
        releases.append(rc)

# Set upgrade versions to target for each release
matrix = {release: [] for release in releases}

for start_version, _ in matrix.items():
    matrix[start_version] = [
        release
        for release in releases
        if int(release.split('.')[0][1:]) > int(start_version.split('.')[0][1:])]

# Assemble matrix include section:
includes = []
for version, upgrades in matrix.items():
    if version not in SKIP_STARTING_VERSIONS:
        if upgrades:
            for upgrade in upgrades:
                if upgrade not in SKIP_TARGET_VERSIONS:
                    includes.append({'gaia_version': version, 'upgrade_version': upgrade})
        else: # Add main branch build
            includes.append({'gaia_version': version, 'upgrade_version': 'main'})

upgrade_json = json.dumps({'include': includes})
print(upgrade_json)
