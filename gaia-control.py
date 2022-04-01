#!/usr/bin/env python3

"""
Ansible-backed node management operations:
./gaia-control.py -o <operation> [-i <inventory file>]
-i is optional, it defaults to inventory.yml
Operations:
restart: restarts the gaiad/cosmovisor service
stop: stops the gaiad/cosmovisor service
start: starts the gaiad/cosmovisor service
reset: resets the gaia database
reboot: reboots the host
"""

import sys
import argparse
import os

parser = argparse.ArgumentParser()
parser.add_argument('-i', '--inventory', required=False,
                    default="inventory.yml")
parser.add_argument('-o', '--operation', required=True)

args = parser.parse_args()

operation = args.operation
inventory = args.inventory

if operation == "restart":
    print(os.popen("ansible-playbook gaia.yml -i " +
                   inventory + " --tags 'gaiad_restart'").read())
    sys.exit(0)

if operation == "stop":
    print(os.popen("ansible-playbook gaia.yml -i " +
                   inventory + " --tags 'gaiad_stop'").read())
    sys.exit(0)

if operation == "start":
    print(os.popen("ansible-playbook gaia.yml -i " +
                   inventory + " --tags 'gaiad_start'").read())
    sys.exit(0)

if operation == "reset":
    answer = input(
        "This will reset gaiad database on all nodes in inventory. "
        "Are you sure you want to continue (yes/no)? ")
    if answer.lower() in ["yes"]:
        print(os.popen("ansible-playbook gaia.yml -i " +
                       inventory +
                       " --extra-vars 'gaiad_unsafe_reset=true' "
                       " --tags 'gaiad_stop,gaiad_reset,gaiad_start'").read())
        sys.exit(0)
    else:
        print("Aborting...")
        sys.exit(2)

if operation == "reboot":
    print(os.popen("ansible-playbook gaia.yml -i " + inventory +
                   " --extra-vars 'reboot=true' --tags 'reboot'").read())
    sys.exit(0)

else:
    print("Invalid operation.")
    sys.exit(1)
