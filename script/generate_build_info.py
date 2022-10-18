#!/usr/bin/env python3

from distutils.log import ERROR, INFO, WARN
from logging import WARNING

import os
import json

class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

class log_type:
    INFO = 0,
    WARNING = 1,
    ERROR = 2,
    HEADER = 3,
    CONTENT = 4

def log(type:log_type, text:str):
    color = ''
    if type == log_type.INFO:
        color = bcolors.OKGREEN
    elif type == log_type.WARNING:
        color = bcolors.WARNING
    elif type == log_type.ERROR:
        color = bcolors.FAIL
    elif type == log_type.HEADER:
        color = bcolors.HEADER
    elif type == log_type.CONTENT:
        color = bcolors.OKCYAN
    
    print(color + text + bcolors.ENDC)
    


def get_files_list(dirname:str, recursive:bool=True):
    file_list = []
    for file in os.listdir(dirname):
        current_file = os.path.join(dirname, file)
        if recursive and os.path.isdir(current_file):
            file_list = file_list + get_files_list(current_file, recursive)
        else:
            file_list.append(current_file)
    return file_list
        


path_separator = os.path.sep
ROOT = path_separator.join(os.getcwd().split(path_separator)[:-1])

package_name = input("Enter Package name (Package name should match with the directory name): ")
#package_name = 'elasticsearch'
package_name = package_name.lower()
dir_name = f"{ROOT}{path_separator}{package_name[0]}{path_separator}{package_name}"

if os.path.exists(dir_name):
    log(log_type.INFO, "Package directory exist !!!")
else:
    log(log_type.ERROR, f"Failed to get the directory for package {package_name}, please check the package name !!!")


build_scripts_versions = []
dockerfile_versions = []
github_url = ''

file_list = get_files_list(dir_name)
for file in file_list:
    if file.endswith(".sh") and "Dockerfiles" not in file:
        with open(file, 'r') as f:
            contents = f.readlines()
            for line in contents:
                if not github_url and line.startswith('# Source repo') :
                    github_url = ":".join(line.split(':')[1:]).strip()
                elif line.startswith('# Package'):
                    pname = line.split(':')[1].strip().lower()
                    if package_name.lower() != pname:
                        log(WARNING, f"Found change in package name in {file}")
                elif line.startswith('# Version'):
                    build_scripts_versions.append( {'version': line.split(':')[1].strip(),
                                                    'file': file.replace(dir_name, '').strip(path_separator)})
    elif 'Dockerfile' in file.split(path_separator)[-1]:
        docker_details = {}
        with open(file, 'r') as f:
            contents = f.readlines()
            docker_details['dir'] = file.replace(dir_name, '').strip(path_separator).replace('Dockerfiles','').strip(path_separator).split(path_separator, 2)[0]
            file.split(path_separator)
            for line in contents:
                if line.lower().startswith('from '):
                    docker_details ['base_image'] = line.split(' ')[1].strip()
                if line.lower().startswith('arg ') and 'version' in line.lower():
                    line = line.replace('=', ' ', 1)
                    if len(line.split(' ')) > 2:
                        docker_details ['version'] = line.split(' ')[2].strip()
                if line.lower().startswith('arg ') and 'patch' in line.lower():
                    line = line.split(' ')[1]
                    patch_details = line.split('=', 1)
                    docker_details [patch_details[0].strip()] = patch_details[1].strip()
        if 'version' not in docker_details:
            docker_details ['version'] = '*'
        dockerfile_versions.append(docker_details)

# print(github_url)
# print(build_scripts_versions)
# print(dockerfile_versions)


final_json = {
    "package_name" : package_name,
    "github_url": github_url,
    "package_dir": dir_name.replace(ROOT, '').strip(path_separator)
}

for entry in dockerfile_versions:
    final_json[entry['version']] = {
        'dir': entry['dir']
    }
    for build_script_entry in build_scripts_versions:
        if build_script_entry['version'] in entry['version']:
            final_json[entry['version']]['build_script'] = build_script_entry['file']
    
    for k in entry:
        if 'patch' in k.lower():
            final_json[entry['version']][k] = entry[k]

log(log_type.HEADER, "Sample Json contents as below")
log(log_type.HEADER, "-" * 25)
log(log_type.CONTENT, json.dumps(final_json, indent = 3))
log(log_type.ERROR, "Note: Above contents are automatically generated, please verify/review before commit it to github.")
