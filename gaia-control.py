#!/usr/bin/env python3

import sys, argparse, os

parser = argparse.ArgumentParser(description='Configure PANIC user_config_nodes.ini file')
subparser = parser.add_subparsers()
parser.add_argument('-i', '--inventory', required=False, default="inventory.yml")
parser.add_argument('-o', '--operation', required=True)

args = parser.parse_args()

operation = args.operation
inventory = args.inventory

if operation == "restart":
	print(os.popen("ansible-playbook gaia.yml -i " + inventory + " --tags 'gaiad_restart'").read())
	sys.exit(0)

if operation == "stop":
	print(os.popen("ansible-playbook gaia.yml -i " + inventory + " --tags 'gaiad_stop'").read())
	sys.exit(0)

if operation == "start":
	print(os.popen("ansible-playbook gaia.yml -i " + inventory + " --tags 'gaiad_start'").read())
	sys.exit(0)

if operation == "reset":
	answer = input("This will reset gaiad database on all nodes in inventory. Are you sure you want to continue (yes/no)? ")
	if answer.lower() in ["yes"]:
		print(os.popen("ansible-playbook gaia.yml -i " + inventory + " --extra-vars 'gaiad_unsafe_reset=true' --tags 'gaiad_stop,gaiad_reset,gaiad_start'").read())
		sys.exit(0)
	else:
		print("Aborting...")
		sys.exit(2)

if operation == "reboot":
	print(os.popen("ansible-playbook gaia.yml -i " + inventory + " --extra-vars 'reboot=true' --tags 'reboot'").read())
	sys.exit(0)

else:
	print("Invalid operation.")
	sys.exit(1)
