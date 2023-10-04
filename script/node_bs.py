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
from datetime import date


GITHUB_PACKAGE_INFO_API = "https://api.github.com/repos/{}/{}/{}/{}"


path_separator = os.path.sep
#ROOT = os.path.dirname(os.path.dirname(__file__))
ROOT = os.getcwd()
package_name = input("Enter Package name (Package name should match with the directory name): ")
#package_name = 'elasticsearch'
package_name = package_name.lower()
dir_name = f"{ROOT}{path_separator}{package_name[0]}{path_separator}{package_name}"


github_url=''
latest_release=''
active_repo=False
new_build_script=''
branch_pkg=""


def get_latest_build_script(dir_name):
    files_path = os.path.join(dir_name,"*")
    files = sorted(glob.iglob(files_path),key=os.path.getctime,reverse=True)
    latest_existing_build_script =""
    for script_file in files:
        if script_file.endswith(".sh") and (script_file.find("ubuntu")==-1):
            global github_url
            github_url = get_repo_url(script_file)
            global active_repo
            if github_url!="NUrl" and github_url!='':
                if (check_repo_activeness(github_url)):
                    active_repo = True
                    global latest_release
                    latest_release = get_latest_release(github_url)
                else:
                    active_repo = False
                    print("\n Repo is Not active . Stopping the further process.")
                    exit()

            return script_file

    return "NPresent"

def get_repo_url(script_file):
    with open(script_file,'r',encoding='utf-8') as f:
        contents=f.readlines()
        for line in contents:
            if line.startswith('# Source repo') :
                github_url = ":".join(line.split(':')[1:]).strip()
                return github_url
    return "NUrl"

def check_repo_activeness(package_url):
    owner, repo = package_url.replace('.git','').split('/')[-2:]
    active_response=requests.get(GITHUB_PACKAGE_INFO_API.format(owner,repo,'branches','master'))

   
    last_commit_date=active_response.json()["commit"]["commit"]["committer"]["date"]
    last_commit_year=last_commit_date.split('-')[0]
    today_date=str(date.today())
    today_date=today_date.split('-')[0]

    if (int(today_date) - int(last_commit_year))>=3:
        #print(f"{package_url} Package Not Active")
        return False
    return True

def get_latest_release(package_url):
    owner, repo = package_url.replace('.git','').split('/')[-2:]
    #response = requests.get(GITHUB_PACKAGE_INFO_API.format(owner, repo)).json()
    #release_github_url=GITHUB_PACKAGE_INFO_API+'/latest/releases'
    print("\n Owner :",owner)
    print("\n Repo  :",repo)
    response = requests.get(GITHUB_PACKAGE_INFO_API.format(owner,repo,'releases','latest'))
    if response.status_code!=200:
        print("\n Release Not Present")
        #print("type",type(response.status_code))
    
        #print("Printing Response",response)
    
        response_tag=requests.get("https://api.github.com/repos/{}/{}/{}/{}/{}".format(owner,repo,'git','refs','tags'))
        #print(response_tag)
        latest_tag=response_tag.json()[-1]
        latest_tag=latest_tag['ref'].split('/')[-1]
        print("\n Present Tag:",latest_tag)
        return latest_tag
    else:
        lc_release=response.json()["html_url"]
        lc_release=lc_release.split('/')[-1]
        print("\n Recent Release:",lc_release)
        if response.json()["name"]=="":
            return lc_release
    
    return response.json()["name"]


def raise_pull_request(branch_pkg):

    print("\n Creating Pull Request")
    user_name=input("Enter username:")

    pr_owner = "ppc64le"  
    github_token=input("Enter github token:")
    
    pr_repo = "build-scripts"

    pr_title = "Currency: Added build_script and build_info.json for "+package_name
    base ="master"
    
    head="{}:{}".format(user_name,branch_pkg)
    maintainer_can_modify = True
    draft = False

    headers = {
            "Accept": "application/vnd.github.v3+json",
            "Authorization": "Bearer {}".format(github_token)
    }

    pull_request_data={
            "title": pr_title,
            "body" : "Adding build_script and build_info.json",
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
    print("\n PR response text",response.text)
    if response.status_code >=200 and response.status_code <=299 :
        return {"message" : "success"}
    return {"message" : "fail"}



def create_new_script():

            
    #new_cmd="python3 script/trigger_container.py -f script/template.sh"

    branch_chout=f"git checkout -b {package_name}_automation"
    branch_pkg=f"{package_name}_automation"
    print("\n\n Creating Branch and Checking Out")
    subprocess.Popen(branch_chout,shell=True)

    branch_cmd=f"git branch"
    print("\n\n Printing Current Branch")
    subprocess.Popen(branch_cmd,shell=True)
    
    current_directory = os.getcwd()
    
    with open(f"{current_directory}/script/template.sh",'r') as newfile:
        template_lines=newfile.readlines()

    for i in range(len(template_lines)):
        if template_lines[i].startswith("PACKAGE_VERSION"):
            temp_rel="${1:-"
            temp_rel=temp_rel+latest_release+"}"
            template_lines[i]= f"PACKAGE_VERSION={temp_rel}\n"
        elif template_lines[i].startswith('# Version'):
            template_lines[i]= f"# Version          : {latest_release}\n"
        elif template_lines[i].startswith("PACKAGE_URL"):
            template_lines[i]=f"PACKAGE_URL={github_url}\n"
        elif template_lines[i].startswith("# Source repo"):
            template_lines[i]= f"# Source repo      : {github_url}\n"
        elif template_lines[i].startswith("# Package"):
            template_lines[i]=f"# Package          : {package_name}\n"
        elif template_lines[i].startswith("PACKAGE_NAME"):
            template_lines[i]=f"PACKAGE_NAME={package_name}\n"
        
    #with open (f"{current_directory}/script/template.sh",'w') as newfile:
        #newfile.writelines(template_lines)

    with open (f"{dir_name}/{package_name}_ubi_8.7.sh",'w') as newfile:
        newfile.writelines(template_lines)

    shutil.copyfile(f"{current_directory}/script/template.sh",f"{dir_name}/{package_name}_ubi_8.7.sh")
    new_cmd=f"python3 script/trigger_container.py -f {dir_name}/{package_name}_ubi_8.7.sh"
     
        #new_cmd="python3 test.py -f latest_build_script.sh"
    container_result=subprocess.Popen(new_cmd,shell=True)
    stdout, stderr=container_result.communicate()
    exit_code=container_result.wait()
    #print("\n PRinting exit code")
    #print(exit_code)
   
    cmd_2=f"python3 script/generate_build_info.py {package_name}"
    print("\n\n Generating build_info.json")
    build_info_w=subprocess.Popen(cmd_2,shell=True)
    build_info_w.wait()
    

    #git add commands
    print("printing currecnt directory before adding \n",os.getcwd())
    print("printing dir_name",dir_name)
    print("printing package_name",package_name)


    user_push_response = input("Do you wish to commit and push this code ? (y/n):")
    user_push_response=user_push_response.lower()
    if user_push_response=='y':

        cmd_add=f"git add {dir_name}/{package_name}_ubi_8.7.sh"
        print("\n\n Git Adding build_script")
        git_add_w=subprocess.Popen(cmd_add,shell=True)
        git_add_w.wait()

        cmd_add=f"git add {dir_name}/build_info.json"
        print("\n\n Git Adding build_info.json")
        git_add_w=subprocess.Popen(cmd_add,shell=True)
        git_add_w.wait()

        #git commit command
        commit_msg="Added build_script and Build_info.json using automation for "+ package_name
        cmd_commit=f"git commit -m \"{commit_msg}\" "
        print("\n\n Commiting")
        git_commit_w=subprocess.Popen(cmd_commit,shell=True)
        git_commit_w.wait()
    
        #git push commands
        cmd_push=f"git push origin {package_name}_automation"
        print("\n\n pushing code")
        git_push_w=subprocess.Popen(cmd_push,shell=True)
        git_push_w.wait()
        
        user_pr_response=input("Do you wish to create a Pull Request ? (y/n):")
        user_pr_response=user_pr_response.lower()

        if user_push_response=='y':
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
if old_script!="NPresent":
    print("\n ** Old Script Present**")
    display_details()
    create_new_script()
    #print(f"old script name : {old_script}")
    #print("directory",os.getcwd())
else:
    print("\n Old_script not Present")



