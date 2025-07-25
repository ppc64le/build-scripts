from distutils.log import ERROR, INFO, WARN
from logging import WARNING

import os
import json
import requests
import subprocess
from subprocess import call
import glob
import stat
import docker
import shutil
import sys
import argparse
from datetime import date


GITHUB_PACKAGE_INFO_API = "https://api.github.com/repos/{}/{}/{}/{}"
GITHUB_PACKAGE_INFO_API_2 = "https://api.github.com/repos/{}/{}"

parser = argparse.ArgumentParser(description='Automation of Manage Currency Package Addition')

parser.add_argument('--package_name_arg', help='Name of the package')
parser.add_argument('--package_dir_arg',help='Package directory')
parser.add_argument('--package_version_arg', help='Version of package to be ported')
parser.add_argument('--github_url_arg', help='Github URL the of package')
parser.add_argument('--language_arg',help="Language Targetted")
parser.add_argument('--spawn_container_arg',action='store_true' ,help="Spawn Docker Container,Test script")
parser.add_argument('--generate_wheel_arg',action='store_true', help="Generate wheel")
parser.add_argument('--commit_files_arg',action='store_true',help="Commit and push files.")
parser.add_argument('--create_PR_arg',action='store_true',help="Raise a Pull Request")
parser.add_argument('--github_username_arg',help="GitHub Username")
parser.add_argument('--github_token_arg',help="GitHub Token")
args=parser.parse_args()

path_separator = os.path.sep
#ROOT = os.path.dirname(os.path.dirname(__file__))
ROOT = os.getcwd()
if args.package_name_arg:
    package_name = args.package_name_arg
else:
    package_name = input("Enter Package name (Package name should match with the directory name): ")
    #package_name = 'elasticsearch'
package_name = package_name.lower()
dir_name = f"{ROOT}{path_separator}{package_name[0]}{path_separator}{package_name}"

try:
    user_name_command ="git config user.name"
    user_name_response = subprocess.check_output(user_name_command,shell=True)
    user_name_response = user_name_response.decode("utf-8")
    user_name_response=''.join(user_name_response.split('\n'))
except subprocess.CalledProcessError as e:
    print("User name not set in Config")
    name_command = f'git config user.name "ICH"'
    user_name_response = subprocess.check_output(name_command,shell=True)
    user_name_response = 'ICH'
except Exception as e:
    print("Error")

try:
    email_command = "git config user.email"
    user_email_response = subprocess.check_output(email_command,shell=True)
    user_email_response = user_email_response.decode("utf-8")
    user_email_response=''.join(user_email_response.split('\n'))
except subprocess.CalledProcessError as e:
    print("User email not set in Config")
    email_command = f'git config user.email "ich@us.ibm.com"'
    user_email_response = subprocess.check_output(email_command,shell=True)
    user_email_response = 'ich@us.ibm.com'
except Exception as e:
    print("Error")

github_url=args.github_url_arg
latest_release = args.package_version_arg
package_language = args.language_arg

active_repo=False
new_build_script=''
branch_pkg=""

def select_template_script(package_language):
    package_language=package_language.lower()
    if package_language == 'node' or package_language == 'javascript':
        return 'build_script_node.sh'
    elif package_language == 'go':
        return 'build_script_go.sh'
    elif package_language == 'python':
        return 'build_script_python.sh'
    elif package_language == 'r' or package_language == 'R':
        return 'build_script_r.sh'
    elif package_language =='java' or package_language =='Java':
        return 'build_script_java.sh'


def get_latest_build_script(dir_name):
    files_path = os.path.join(dir_name,"*")
    files = sorted(glob.iglob(files_path),key=os.path.getctime,reverse=True)
    latest_existing_build_script =""
    for script_file in files:
        if script_file.endswith(".sh") and script_file.find("ubuntu")<0:
            global github_url
            github_url = get_repo_url(script_file)
            global active_repo
            if github_url!=False and github_url!='':
                if (check_repo_activeness(github_url)):
                    active_repo = True
                else:
                    active_repo = False
                    print("\n Repo is Not active . Stopping the further process.")
                    exit()

            return script_file

    return False

def get_repo_url(script_file):
    with open(script_file,'r',encoding='utf-8') as f:
        contents=f.readlines()
        for line in contents:
            if line.startswith('# Source repo') :
                github_url = line.split(':', 1)[1].strip()
                return github_url
    return False

def get_default_branch(package_url):
    owner, repo = package_url.replace('.git','').split('/')[-2:]
    response = requests.get(GITHUB_PACKAGE_INFO_API_2.format(owner, repo)).json()
    return response["default_branch"]

def check_repo_activeness(package_url):
    owner, repo = package_url.replace('.git','').split('/')[-2:]
    def_branch = get_default_branch(package_url)
    active_response=requests.get(GITHUB_PACKAGE_INFO_API.format(owner,repo,'branches',def_branch))

   
    last_commit_date=active_response.json()["commit"]["commit"]["committer"]["date"]
    if last_commit_date == "":
        return False
    last_commit_year=last_commit_date.split('-')[0]
    today_date=str(date.today())
    today_date=today_date.split('-')[0]

    if (int(today_date) - int(last_commit_year))>=3:
        return False
    return True


def raise_pull_request(branch_pkg, base="master"):

    print("\n Creating Pull Request")
    if args.github_username_arg:
        user_name=args.github_username_arg
    else:
        user_name=input("Enter Github username:")

    pr_owner = "ppc64le"
    if args.github_token_arg:
        github_token = args.github_token_arg
    else:
        github_token = input("Enter github token:")
    
    pr_repo = "build-scripts"

    pr_title = "Currency: Added build_script and build_info.json for "+package_name
    
    head="{}:{}".format(user_name,branch_pkg)
    maintainer_can_modify = True
    draft = False

    headers = {
            "Accept": "application/vnd.github.v3+json",
            "Authorization": "Bearer {}".format(github_token)
    }

    #Check if PR already exists
    search_url = f"https://api.github.com/repos/{pr_owner}/{pr_repo}/pulls?head={head}&state=open"
    existing_pr_response = requests.get(search_url, headers=headers)

    if existing_pr_response.status_code == 200:
        existing_prs = existing_pr_response.json()
        if existing_prs:
            print("\nPR already exists.")
            return {
                "message": "already_exists",
                "pr_url": existing_prs[0].get("html_url")
            }

    pr_body = "Adding build_script and build_info.json"

    if package_language == "python" and args.generate_wheel_arg:
        pr_title = "Python Ecosystem: Added build_script and build_info.json for "+package_name
        with open('./templates/pyeco_pull_request_description.md', 'r') as file:
            pr_body = file.read()
		
    pull_request_data={
            "title": pr_title,
            "body" : pr_body,
            "head" : head,
            "base" : base,
            "maintainer_can_modify" : maintainer_can_modify,
            "draft" : draft
    }
    print("\n Head:",head)

    pull_request_url = "https://api.github.com/repos/{}/{}/pulls".format(pr_owner, pr_repo)
    response = requests.post(
				pull_request_url,
                                json = pull_request_data,
				headers = headers
    )
    print("\n PR response" ,response)
    print("\n PR status code",response.status_code)
    
    if response.status_code >=200 and response.status_code <=299 :
        pr_data = response.json()
        return {
            "message": "success",
            "pr_url": pr_data.get("html_url")
        }

    return {"message" : "fail"}

def add_license_file():
    if not os.path.exists(f"{dir_name}/LICENSE"):
        current_directory = os.getcwd()
        shutil.copy(f"{current_directory}/LICENSE",dir_name)
        return True
    return False


def create_new_script():       
    branch_chout=f"git checkout -b {package_name}_{latest_release}_automation"
    branch_pkg=f"{package_name}_{latest_release}_automation"
    print("\n\n Creating Branch and Checking Out")
    subprocess.Popen(branch_chout,shell=True)

    branch_cmd=f"git branch"
    print("\n\n Printing Current Branch")
    subprocess.Popen(branch_cmd,shell=True)
    
    current_directory = os.getcwd()

    license_added = add_license_file()

    script_language=select_template_script(package_language)
    print("\n template script selected ",script_language)
    
    with open(f"{current_directory}/templates/{script_language}",'r') as newfile:
        template_lines=newfile.readlines()

    for i in range(len(template_lines)):
        if template_lines[i].startswith("PACKAGE_VERSION"):
            temp_rel="${1:-"
            temp_rel=temp_rel+latest_release+"}"
            template_lines[i]= f"PACKAGE_VERSION={temp_rel}\n"
        elif template_lines[i].startswith('# Version'):
            template_lines[i]= f"# Version          : {latest_release}\n"

        elif template_lines[i].startswith("# Maintainer"):
            template_lines[i]=f"# Maintainer    : {user_name_response} <{user_email_response}>\n"
        elif template_lines[i].startswith("PACKAGE_URL"):
            template_lines[i]=f"PACKAGE_URL={github_url}\n"
        elif template_lines[i].startswith("# Source repo"):
            template_lines[i]= f"# Source repo      : {github_url}\n"
        elif template_lines[i].startswith("# Package"):
            template_lines[i]=f"# Package          : {package_name}\n"
        elif template_lines[i].startswith("PACKAGE_NAME"):
            template_lines[i]=f"PACKAGE_NAME={package_name}\n"
        elif template_lines[i].startswith("PACKAGE_DIR"):
            template_lines[i]=f"PACKAGE_DIR={package_name}\n"
        
    with open (f"{dir_name}/{package_name}_ubi_9.3.sh",'w') as newfile:
        newfile.writelines(template_lines)

    if args.spawn_container_arg:
        new_cmd=f"python3 gha-script/trigger_container.py -f {package_name[0]}/{package_name}/{package_name}_ubi_9.3.sh"
        container_result=subprocess.Popen(new_cmd,shell=True)
        stdout, stderr=container_result.communicate()
        exit_code=container_result.wait()   
   
    cmd_2=f"python3 gha-script/generate_build_info.py --package_name_arg {package_name} --github_username_arg {args.github_username_arg} --generate_wheel_arg"
    print("\n\n Generating build_info.json")
    build_info_w=subprocess.Popen(cmd_2,shell=True)
    build_info_w.wait()
    

    #git add commands
    print("printing currecnt directory before adding \n",os.getcwd())
    print("printing dir_name",dir_name)
    print("printing package_name",package_name)

    if args.commit_files_arg:
        user_push_response='y'
    else:
        user_push_response = input("Do you wish to commit and push this code ? (y/n):")
        user_push_response=user_push_response.lower()

    if user_push_response=='y':

        cmd_add=f"git add {dir_name}/{package_name}_ubi_9.3.sh"
        print("\n\n Git Adding build_script")
        git_add_w=subprocess.Popen(cmd_add,shell=True)
        git_add_w.wait()

        cmd_add=f"git add {dir_name}/build_info.json"
        print("\n\n Git Adding build_info.json")
        git_add_w=subprocess.Popen(cmd_add,shell=True)
        git_add_w.wait()

        if license_added:
            cmd_add=f"git add {dir_name}/LICENSE"
            print("\n\n Git Adding LICENSE")
            git_add_w=subprocess.Popen(cmd_add,shell=True)
            git_add_w.wait()


        #git commit command
        commit_msg="Added build_script and Build_info.json using automation for "+ package_name
        cmd_commit=f"git commit -m \"{commit_msg}\" "
        print("\n\n Commiting")
        git_commit_w=subprocess.Popen(cmd_commit,shell=True)
        git_commit_w.wait()
    
        #git push commands
        cmd_push=f"git push origin {package_name}_{latest_release}_automation"
        print("\n\n pushing code")
        git_push_w=subprocess.Popen(cmd_push,shell=True)
        git_push_w.wait()
        
        if args.create_PR_arg:
            user_pr_response='y'
        else:
            user_pr_response=input("Do you wish to create a Pull Request ? (y/n):")
            user_pr_response=user_pr_response.lower()

        if user_pr_response=='y':
            pull_request_response = raise_pull_request(branch_pkg)
            print(pull_request_response)
            if pull_request_response['message']=="success":
                print("\n\n Pull Request Created Successfully")
            else:
                print("\n\n Pull Request Not Created")
        else:
            print("\n Not Creating Pull Request")
    else :
        print("\n Not Pushing code")
        exit()

  
    
def display_details():
    print(f"\n\n Github URL :{github_url}")
    print(f"\n\n Latest Release: {latest_release}")
    print(f"\n\n Repo Activeness: {active_repo}")


old_script=get_latest_build_script(dir_name)
if old_script!=False:
    print("\n ** Old Script Present**")
    display_details()
    create_new_script()   
else:
    print("\n Old_script not Present")
    if args.github_url_arg:
        github_url = args.github_url_arg
    else:
        github_url=input("Enter Github URL:")

    if args.package_version_arg:
        latest_release=args.package_version_arg
    else:
        latest_release=input("Enter version/tag to build:")

    if args.language_arg:
        package_language = args.language_arg
    else:
        package_language=input("Enter Package Language (node,go,python):")

    if args.package_name_arg:
        package_name = args.package_name_arg
    else:
        package_name = input("Enter Package name (Package name should match with the directory name): ")

    if args.package_dir_arg:
        package_dir = args.package_dir_arg

    package_name = package_name.lower()
    dir_name = f"{ROOT}{path_separator}{package_name[0]}{path_separator}{package_name}"
    os.makedirs(dir_name, exist_ok = True)
    create_new_script()
    display_details()
