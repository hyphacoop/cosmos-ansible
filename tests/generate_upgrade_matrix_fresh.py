#!/usr/bin/env python

import json
# import sys
import re
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('starting_version')
parser.add_argument('-r', '--relayer', action='store_true')
args = parser.parse_args()
RELAYER = args.relayer

SKIP_TARGET_VERSIONS = ['v14.0.0-rc0','v14.0.0-rc1','v14.0.0', 'v14.1.0-rc0']

# Must provide a cutoff version, e.g. 'v6.0.4'
# starting_version = sys.argv[1].split('.')
starting_version = args.starting_version.split('.')
version_major = int(starting_version[0][1:])
version_minor = int(starting_version[1])
version_patch = int(starting_version[2])

# Read JSON output from generate_version_matrix.py
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
    if (int(components[0][1:]) == version_major and (int(components[1]) >= version_minor)) and \
       (int(components[0][1:]) == version_major and (int(components[2].split('-')[0]) >= version_patch)) or \
        int(components[0][1:]) > version_major:
        if 'rc' in components[2]:
            rc_releases.append(name)
        else:
            releases.append(name)

# Remove all rcs from the list if there is a final release available
for rc in rc_releases:
    components = rc.split('.')
    if int(components[0][1:]) > version_major:
        releases.append(rc)

# Set upgrade versions to target for each release
# matrix = {release: [] for release in releases}
matrix = {}
for release in releases:
    rel_major_version = int(release.split('.')[0][1:])
    if rel_major_version == version_major:
        matrix[release] = []

for start_version, _ in matrix.items():
    matrix[start_version] = [
        release
        for release in releases
        if int(release.split('.')[0][1:]) > int(start_version.split('.')[0][1:])]

# Assemble matrix include section:
includes = []
for version, upgrades in matrix.items():
    if upgrades:
        for upgrade in upgrades:
            if upgrade not in SKIP_TARGET_VERSIONS:
                if RELAYER:
                    includes.append({'gaia_version': version, 'upgrade_version': upgrade, 'upgrade_mechanism': 'binary', 'relayer': 'hermes'})
                    # includes.append({'gaia_version': version, 'upgrade_version': upgrade, 'upgrade_mechanism': 'binary', 'relayer': 'rly'})
                else:
                    includes.append({'gaia_version': version, 'upgrade_version': upgrade, 'upgrade_mechanism': 'binary'})
                # includes.append({'gaia_version': version, 'upgrade_version': upgrade, 'upgrade_mechanism': 'cv_manual', 'cv_version': 'v1.5.0'})
                # includes.append({'gaia_version': version, 'upgrade_version': upgrade, 'upgrade_mechanism': 'cv_manual', 'cv_version': 'v1.4.0'})
                # includes.append({'gaia_version': version, 'upgrade_version': upgrade, 'upgrade_mechanism': 'cv_manual', 'cv_version': 'v1.3.0'})
                # includes.append({'gaia_version': version, 'upgrade_version': upgrade, 'upgrade_mechanism': 'cv_auto', 'cv_version': 'v1.5.0'})
                # includes.append({'gaia_version': version, 'upgrade_version': upgrade, 'upgrade_mechanism': 'cv_auto', 'cv_version': 'v1.4.0'})
                # includes.append({'gaia_version': version, 'upgrade_version': upgrade, 'upgrade_mechanism': 'cv_auto', 'cv_version': 'v1.3.0'})

    else: # Add main branch build
        if RELAYER:
            includes.append({'gaia_version': version, 'upgrade_version': 'main', 'upgrade_mechanism': 'binary', 'relayer': 'hermes'})
            # includes.append({'gaia_version': version, 'upgrade_version': 'main', 'upgrade_mechanism': 'binary', 'relayer': 'rly'})
        else:
            includes.append({'gaia_version': version, 'upgrade_version': 'main', 'upgrade_mechanism': 'binary'})
        # includes.append({'gaia_version': version, 'upgrade_version': 'main', 'upgrade_mechanism': 'cv_manual', 'cv_version': 'v1.5.0'})
        # includes.append({'gaia_version': version, 'upgrade_version': 'main', 'upgrade_mechanism': 'cv_manual', 'cv_version': 'v1.4.0'})
        # includes.append({'gaia_version': version, 'upgrade_version': 'main', 'upgrade_mechanism': 'cv_manual', 'cv_version': 'v1.3.0'})
        # includes.append({'gaia_version': version, 'upgrade_version': 'main', 'upgrade_mechanism': 'cv_auto', 'cv_version': 'v1.5.0'})
        # includes.append({'gaia_version': version, 'upgrade_version': 'main', 'upgrade_mechanism': 'cv_auto', 'cv_version': 'v1.4.0'})
        # includes.append({'gaia_version': version, 'upgrade_version': 'main', 'upgrade_mechanism': 'cv_auto', 'cv_version': 'v1.3.0'})


upgrade_json = json.dumps({'include': includes})
print(upgrade_json)
