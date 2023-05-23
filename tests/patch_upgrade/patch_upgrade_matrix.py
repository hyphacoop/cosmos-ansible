#!/usr/bin/env python

import json
import requests

# SKIP_VERSIONS = ['v8.0.0-rc',   # software-upgrade command not available
                #  'v8.0.0-rc1']  # unsuccessful upgrade to v9.0.0-rc3 through v9.0.0: https://github.com/hyphacoop/cosmos-ansible/actions/runs/4319476707

# Set start version
gaia_releases = requests.get(
    'https://api.github.com/repos/cosmos/gaia/releases', timeout=30).json()

for release in gaia_releases:
    if 'rc' not in release['name']:
        start_version = release['name']
        version_parts = start_version.split('.')
        start_major_version = int(version_parts[0][1:])
        start_minor_version = int(version_parts[1])
        start_patch_version = int(version_parts[2])
        break

target_rc_version = ''
for release in gaia_releases:
    if 'rc' in release['name']:
        version_parts =  release['name'].split('.')
        rc_major_version = int(version_parts[0][1:])
        rc_minor_version = int(version_parts[1])
        rc_patch_version = int(version_parts[2].split('-')[0])
        if (rc_major_version == start_major_version) and \
           ((rc_minor_version == start_minor_version) and \
           (rc_patch_version > start_patch_version)):
            target_rc_version = release['name']
            break

# Assemble matrix include section:
includes = [
    {'start_version': start_version, 'target_branch': f'release-v{start_major_version}', 'upgrade_coverage': 'full'},
    {'start_version': start_version, 'target_branch': f'release-v{start_major_version}', 'upgrade_coverage': 'partial'},
    {'start_version': start_version, 'target_branch': 'main', 'upgrade_coverage': 'full'},
    {'start_version': start_version, 'target_branch': 'main', 'upgrade_coverage': 'partial'},
]

if target_rc_version:
    includes.append({'start_version': start_version, 'target_branch': target_rc_version, 'upgrade_coverage': 'full'})
    includes.append({'start_version': start_version, 'target_branch': target_rc_version, 'upgrade_coverage': 'partial'})



upgrade_json = json.dumps({'include': includes})
print(upgrade_json)
