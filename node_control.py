#!/usr/bin/env python3

"""
Ansible-backed node management operations:
./node-control.py [-i <inventory file>] [-t target] <operation>
-i is optional, it defaults to inventory.yml
The target option is the server IP or domain
Operations:
restart: restarts the chain service
stop: stops the chain service
start: starts the chain service
reset: resets the chain database
reboot: reboots the host
"""

import sys
import argparse
import os

parser = argparse.ArgumentParser(description='Single-command node management.')
parser.add_argument('-i', metavar='inventory', help='inventory file (default: inventory.yml)',
                    required=False,
                    default='inventory.yml')
parser.add_argument('-t', metavar='target', help='target server',
                    required=False,
                    default='')
parser.add_argument('operation', help='the operation to perform')

args = parser.parse_args()

operation = args.operation
inventory = args.i
target = args.t

if operation == "restart":
    print(os.popen("ansible-playbook node.yml -i " +
                   inventory + " -e 'target=" + target + " reboot=false' --tags 'chain_restart'").read())
    sys.exit(0)

if operation == "stop":
    print(os.popen("ansible-playbook node.yml -i " +
                   inventory + " -e 'target=" + target + "' --tags 'chain_stop'").read())
    sys.exit(0)

if operation == "start":
    print(os.popen("ansible-playbook node.yml -i " +
                   inventory + " -e 'target=" + target + " reboot=false' --tags 'chain_start'").read())
    sys.exit(0)

if operation == "reset":
    answer = input(
        "This will reset chain database on all nodes in inventory. "
        "Are you sure you want to continue (yes/no)? ")
    if answer.lower() in ["yes"]:
        print(os.popen("ansible-playbook node.yml -i " +
                       inventory +
                       " --extra-vars 'node_unsafe_reset=true target=" + target + "' "
                       " --tags 'chain_stop,chain_reset,chain_start'").read())
        sys.exit(0)
    else:
        print("Aborting...")
        sys.exit(2)

if operation == "reboot":
    print(os.popen("ansible-playbook node.yml -i " + inventory +
                   " --extra-vars 'reboot=true target=" + target + "' --tags 'reboot'").read())
    sys.exit(0)

else:
    print("Invalid operation.")
    sys.exit(1)
