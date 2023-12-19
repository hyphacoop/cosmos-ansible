#!/usr/bin/env python

import json
import sys
import re
import requests

SKIP_VERSIONS = []

# Must provide a cutoff version, e.g. 'v6.0.4'
starting_version = sys.argv[1].split('.')
version_major = int(starting_version[0][1:])
version_minor = int(starting_version[1])
version_patch = int(starting_version[2])

# Read in releases from GitHub API
releases_list = requests.get(
    'https://api.github.com/repos/cosmos/gaia/releases', timeout=30).json()

# Save release list for upgrade matrix script
with open('releases.json', 'w', encoding='utf-8') as outfile:
    json.dump(releases_list, outfile)

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

# Trim list further to remove all releases listed in the SKIP_VERSIONS list
filtered_releases = [release for release in releases if
                     release not in SKIP_VERSIONS ]

start_json = json.dumps(
    {'gaia_version': list(filtered_releases)})
print(start_json)
