#!/usr/bin/env python3

"""
This script takes a JSON config file and patches `.toml` files with its values
"""

import argparse
import json
import toml

parser = argparse.ArgumentParser(
    description="Patch gaiad config files")

parser.add_argument('--gaiad_home')
parser.add_argument('--config_file')

args = vars(parser.parse_args())

gaiad_home = args["gaiad_home"]
config_file = args["config_file"]


def update_config_files(source_config, destination_folder):
    """
    Loads the config JSON file and updates the config files it references
    """
    with open(source_config, "r", encoding="utf8") as file:
        config = json.load(file)
        for file_name, var_map in config.items():
            file_path = destination_folder + "/config/" + file_name
            update_config(file_path, var_map)


def update_config(file_path, var_map):
    """
    Injects variables into a TOML config file from a map of definitions
    The keys in the map are a path within the config file
    The values are the value to set it to
    """
    config = {}
    with open(file_path, "r", encoding="utf8") as file:
        config = toml.load(file)

    for config_path, config_value in var_map.items():
        if config_value == "":
            continue
        set_nested(config, config_path, config_value)

    with open(file_path, "w", encoding="utf8") as file:
        toml.dump(config, file)


def set_nested(nested_dict, path, value):
    """
    Sets a value that's deeply nested within a dict
    """

    segments = path.split('.')
    final_field = segments.pop()
    current_val = nested_dict
    for subpath in segments:
        if subpath in current_val:
            current_val = current_val[subpath]
    current_val[final_field] = value


update_config_files(config_file, gaiad_home)
