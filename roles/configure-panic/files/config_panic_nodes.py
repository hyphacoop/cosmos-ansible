#!/usr/bin/env python3

# pylint: skip-file

import configparser
import sys
import argparse

# argparse
parser = argparse.ArgumentParser(
    description='Configure PANIC user_config_nodes.ini file')
subparser = parser.add_subparsers()
parser.add_argument('--config_file', required=True)

parser_add = subparser.add_parser('add')
parser_add.add_argument('--node_name', required=True)
parser_add.add_argument('--node_rpc_url', required=True)
parser_add.add_argument('--node_rpc_port', required=True)
parser_add.add_argument('--node_is_validator', required=True)
parser_add.add_argument('--include_in_node_monitor', required=True)
parser_add.add_argument('--include_in_network_monitor', required=True)
parser_add.set_defaults(operation='add')

parser_del = subparser.add_parser('del')
parser_del.add_argument('--node_name', required=True)
parser_del.set_defaults(operation='del')

args = parser.parse_args()

filename = args.config_file
new_node_name = args.node_name
operation = args.operation

if operation == 'add':
    new_node_rpc_url = args.node_rpc_url
    new_node_rpc_port = args.node_rpc_port
    new_node_is_validator = args.node_is_validator
    new_include_in_node_monitor = args.include_in_node_monitor
    new_include_in_network_monitor = args.include_in_network_monitor

node_found = 0
node_count = 0
config = configparser.ConfigParser()
config.read(filename)

new_config = configparser.ConfigParser()


def reorder_nodes():
    reorder_count = 0
    for node in config:
        try:
            if node != 'DEFAULT':
                new_node_id = ("node_" + str(reorder_count))
                new_config[new_node_id] = {}
                new_config[new_node_id]['node_name'] = config[node]['node_name']
                new_config[new_node_id]['node_rpc_url'] = config[node]['node_rpc_url']
                new_config[new_node_id]['node_is_validator'] = config[node]['node_is_validator']
                new_config[new_node_id]['include_in_node_monitor'] = config[node]['include_in_node_monitor']
                new_config[new_node_id]['include_in_network_monitor'] = config[node]['include_in_network_monitor']
                reorder_count = reorder_count + 1
        except:
            KeyError
    reorder_nodes.reorder_count = reorder_count
    return


# add and update section
if operation == 'add':
    # check if node already exists and update its values and if not add a new entry
    for node_key, node in config.items():
        try:
            if config[node_key]['node_name'] == new_node_name:
                print("Node:", config[node_key]['node_name'],
                      " already exists in key:", node_key)
                print('Updating the values')
                config[node_key]['node_rpc_url'] = (
                    "http://" + new_node_rpc_url + ":" + new_node_rpc_port)
                if new_node_is_validator == 'yes':
                    config[node_key]['node_is_validator'] = 'true'
                else:
                    config[node_key]['node_is_validator'] = 'false'

                if new_include_in_node_monitor == 'yes':
                    config[node_key]['include_in_node_monitor'] = 'true'
                else:
                    config[node_key]['include_in_node_monitor'] = 'false'

                if new_include_in_network_monitor == 'yes':
                    config[node_key]['include_in_network_monitor'] = 'true'
                else:
                    config[node_key]['include_in_network_monitor'] = 'false'
                node_found = True
            node_count = node_count + 1
        except:
            KeyError

    # if node_found is set write file and quit else add a new node
    if node_found == True:
        with open(filename, 'w') as configfile:
            config.write(configfile)
            print('Updated values in file')
            sys.exit(0)
    else:
        print("Node not found adding to the config")
        reorder_nodes()
        reorder_count = reorder_nodes.reorder_count
        new_node_id = ("node_" + str(reorder_count))
        new_config[new_node_id] = {}
        new_config[new_node_id]['node_name'] = new_node_name
        new_config[new_node_id]['node_rpc_url'] = (
            "http://" + new_node_rpc_url + ":" + new_node_rpc_port)
        if new_node_is_validator == 'yes':
            new_config[new_node_id]['node_is_validator'] = 'true'
        else:
            new_config[new_node_id]['node_is_validator'] = 'false'

        if new_include_in_node_monitor == 'yes':
            new_config[new_node_id]['include_in_node_monitor'] = 'true'
        else:
            new_config[new_node_id]['include_in_node_monitor'] = 'false'

        if new_include_in_network_monitor == 'yes':
            new_config[new_node_id]['include_in_network_monitor'] = 'true'
        else:
            new_config[new_node_id]['include_in_network_monitor'] = 'false'

        with open(filename, 'w') as configfile:
            new_config.write(configfile)
            print('Added new node to file')
            sys.exit(0)

# delete section
elif operation == 'del':
    node_count = 0
    del_node_name = new_node_name
    for node in config:
        try:
            if config[node]['node_name'] == del_node_name:
                node_found = True
                node_num = node_count
            node_count = node_count + 1
        except:
            KeyError

    if node_found != True:
        print('Cannot find node:', del_node_name, 'to delete')
        sys.exit(1)
    else:
        print('Found node:', del_node_name, 'deleting...')
        node_id = ("node_" + str(node_num))
        config.remove_section(node_id)
        reorder_nodes()
        with open(filename, 'w') as configfile:
            new_config.write(configfile)
            sys.exit(0)
