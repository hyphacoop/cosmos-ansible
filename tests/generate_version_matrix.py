#!/usr/bin/env python

import json
import sys
import requests


# Must provide a cutoff version, e.g. 'v6.0.4'
starting_version = sys.argv[1]
version_major = int(starting_version[1])
version_patch = int(starting_version[5])

# Read in releases from GitHub API
releases_list = requests.get(
    'https://api.github.com/repos/cosmos/gaia/releases', timeout=30).json()

# Save release list for upgrade matrix script
with open('releases.json', 'w', encoding='utf-8') as outfile:
    json.dump(releases_list, outfile)

# Trim list to only releases from specified version onwards
trimmed_releases = [release for release in releases_list if
                    (int(release['name'][1]) == version_major and
                     int(release['name'][5]) >= version_patch) or
                    int(release['name'][1]) > version_major]

start_json = json.dumps(
    {'gaia_version': [rel['name'] for rel in trimmed_releases]})
print(start_json)
