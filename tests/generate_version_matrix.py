#!/usr/bin/env python

import json
import requests

# Read in releases from GitHub API
releases_list = requests.get(
    'https://api.github.com/repos/cosmos/gaia/releases').json()

with open('releases.json', 'w') as outfile:
    json.dump(releases_list, outfile)

# Trim list to only releases from 6.0.4 onwards
post_604_releases = [release for release in releases_list if
                     (int(release['name'][1]) == 6 and int(release['name'][5]) == 4) or
                     int(release['name'][1]) > 6]

start_json = json.dumps(
    {'gaia_version': [rel['name'] for rel in post_604_releases]})
print(start_json)
