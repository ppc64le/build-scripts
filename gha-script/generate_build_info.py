#!/usr/bin/env python3

'''
This script is to generate the sample build_info.json file for any package.

Once done with generating build-scripts and Dockerfiles, we can run this script
to generate the sample build_info.json file.

This script parse the package build-scripts and Dockerfiles available in local filesystem,
read the data and generates the build_info contents.

This script can be executed from base build-script repo folder like 
$python3 gha-script/generate_build_info.py

Note : Content generated from this scipt are not final.
       Please review the generated build info data before committing.
'''

from distutils.log import ERROR, INFO, WARN
from logging import WARNING

import os
import json
import requests
import sys
import glob
import argparse


GITHUB_PACKAGE_INFO_API = "https://api.github.com/repos/{}/{}"
GITHUB_USER_API = "https://api.github.com/users/{}"

parser = argparse.ArgumentParser(description='Automation of build_info.json Addition')
parser.add_argument('--package_name_arg', help='Name of the package')
parser.add_argument('--github_username_arg',help="GitHub Username")
parser.add_argument('--generate_wheel_arg',action='store_true', help="Generate wheel")
args=parser.parse_args()

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

def log(type:log_type, *phrases):
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
    
    text = " ".join(phrases)
    
    print(color + text + bcolors.ENDC)
    
def get_default_branch(package_url):
    owner, repo = package_url.replace('.git','').split('/')[-2:]
    response = requests.get(GITHUB_PACKAGE_INFO_API.format(owner, repo)).json()
    return response["default_branch"]

def validate_username(user_name):
    response = requests.get(GITHUB_USER_API.format(user_name))
    if response.status_code==200:
        return True
    return False

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
#ROOT = os.path.dirname(os.path.dirname(__file__))
ROOT = os.getcwd()
if args.package_name_arg:
    package_name=args.package_name_arg
else:
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

default_build_script = None

file_list = get_files_list(dir_name)

def get_maintainer_for_package(dir_name):
    files_path=os.path.join(dir_name,"*")
    files=sorted(glob.iglob(files_path),key=os.path.getctime,reverse=True)
    for script_file in files:
        if script_file.endswith(".sh"):
            with open(script_file, 'r' , encoding='utf-8') as f:
                contents = f.readlines()
                for line in contents:
                    if line.startswith('# Maintainer'):
                        maintainer = line.split(':')[1]
                        maintainer = maintainer.split('<')[1].split('>')[0]
                        return maintainer
    return "Unknown"

def get_maintainer_from_dockerfile(dir_name):
    maintainer=''
    files_path=os.path.join(dir_name,"*")
    files=sorted((glob.glob(files_path + '/**/Dockerfile' , recursive=True)),key=os.path.getctime,reverse=True)
    for docker_file in files:
        with open(docker_file, 'r', encoding='utf-8') as f:
            contents = f.readlines()
            for line in contents:
                line=line.strip()
                if line.startswith('maintainer'):
                    maintainer=line.split('=')[1].split('\"')[1]
                    return maintainer
    return "Unknown"

def get_github_url(build_script):
    with open(build_script,'r',encoding='utf-8') as f:
        contents=f.readlines()
        for line in contents:
            line=line.strip()
            if line.startswith('# Source repo'):
                github_url=line.split(':', 1)[1].strip()
                return github_url
    return False


def get_default_build_script(build_scripts_versions):
    result=[]
    for data in build_scripts_versions:
        if 'ubi_9.3' in data['file']:
            return [data['version'],data['file']]
        else:
            result.append((data['version'],data['file']))
    return max(result,key=lambda x:x[0]) 

if args.github_username_arg:
    maintainer = args.github_username_arg
else:
    maintainer=input("Enter GitHub username (github.com) :")
    user_result = validate_username(maintainer)

    while (maintainer!='' and user_result!=True):
        print("\n Invalid Github Username \n")
        maintainer=input("Please Enter GitHub username (github.com) :")
        user_result = validate_username(maintainer)
        if user_result:
            print("\n Valid Github Username \n")


if args.generate_wheel_arg:
    wheel_build_flag = True
else :
    wheel_build_flag = False

for file in file_list:
    if file.endswith(".sh") and "Dockerfiles" not in file:
        # Read the available build-scripts and load the data.
        with open(file, 'r', encoding='utf-8') as f:
            contents = f.readlines()
            for line in contents:
                if not github_url and line.startswith('# Source repo') :
                    github_url = ":".join(line.split(':')[1:]).strip()
                elif line.startswith('# Package'):
                    pname = line.split(':')[1].strip().lower()
                    if package_name.lower() != pname:
                        log(WARNING, f"Found change in package name in {file}")
                elif line.startswith('# Version'):
                    default_build_script = file.replace(dir_name, '').strip(path_separator)
                    build_scripts_versions.append( {'version': line.split(':')[1].strip(),
                                                    'file': default_build_script})
    elif 'Dockerfile' in file.split(path_separator)[-1]:
        # Read Dockerfiles and store details
        docker_details = {}
        with open(file, 'r') as f:
            contents = f.readlines()
            docker_details['dir'] = os.path.basename(os.path.dirname(file))
            
            for line in contents:
                if line.lower().startswith('from '):
                    docker_details ['base_image'] = line.split(' ')[1].strip()
                if line.lower().startswith('arg ') and 'version' in line.lower():
                    if len(line.split('=')) > 1:
                        docker_details ['version'] = line.split('=')[1].strip()
                if line.lower().startswith('arg ') and 'patch' in line.lower():
                    line = line.split(' ')[1]
                    patch_details = line.split('=', 1)
                    docker_details [patch_details[0].strip()] = patch_details[1].strip()
        if 'version' not in docker_details:
            docker_details ['version'] = '*'
        dockerfile_versions.append(docker_details)
    elif file.endswith(".json"):

        new_key_value = {"maintainer":maintainer}
        build_info_data = json.load(open(f"{dir_name}/build_info.json"))
        
        new_key_value.update(build_info_data)
        updated_build_info = new_key_value
        with open(f"{dir_name}/build_info.json",'w') as f:
            json.dump(updated_build_info,f,indent=2)


default_version,default_build_script=get_default_build_script(build_scripts_versions)
github_url=get_github_url(f"{dir_name}/{default_build_script}")


final_json = {
    "maintainer" : maintainer,
    "package_name" : package_name,
    "github_url": github_url,
    "version": dockerfile_versions[-1]['version'] if dockerfile_versions else default_version,
    "default_branch": get_default_branch(github_url),
    "build_script": default_build_script,
    "package_dir": dir_name.replace(ROOT, '').strip(path_separator),
    "docker_build": True if dockerfile_versions else False,
    "wheel_build" : True if wheel_build_flag else False,
    "validate_build_script": True if build_scripts_versions else False,
    "use_non_root_user":False
}

for entry in dockerfile_versions:
    version = entry['version']
    final_json[version] = {
        'dir': entry['dir'],
    }
    if  entry['base_image']:
        # Store base image and variant depending on base image.
        # These 2 are useful while running LICENSE AUTOMATION tool.        
        base_image = entry['base_image']
        final_json[version]['base_docker_image'] = base_image
        if 'ubi' in base_image.lower() or 'rhel' in base_image.lower():
            final_json[version]['base_docker_variant'] = 'redhat'
        elif 'ubuntu' in base_image.lower() or 'debian' in base_image.lower():
            final_json[version]['base_docker_variant'] = 'ubuntu'
        elif 'alpine' in base_image.lower():
            final_json[version]['base_docker_variant'] = 'alpine'
        else:
            final_json[version]['base_docker_variant'] = 'Not defined'

    for build_script_entry in build_scripts_versions:
        if build_script_entry['version'] in version:
            final_json[version]['build_script'] = build_script_entry['file']
    
    for k in entry:
        if 'patch' in k.lower():
            final_json[version][k] = entry[k]

print("\n\n Creating build_info.json file locally")

with open(f"{dir_name}/build_info.json",'w') as f:
            json.dump(final_json,f,indent = 3)

log(log_type.HEADER, "Sample Json contents as below")
log(log_type.HEADER, "-" * 25)
log(log_type.CONTENT, json.dumps(final_json, indent = 3))
log(log_type.ERROR, "Note: Above contents are automatically generated, please verify/review before commit it to github.")
