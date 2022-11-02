import os
import json
import re

path_separator = os.path.sep
ROOT = path_separator.join(os.path.dirname(os.path.realpath(__file__)).split(path_separator)[:-2])

package_name = 'Vault'
version = 'v1.9.2'

# package_name = 'Elasticsearch'
# version = 'v8.1.1'

package_name = package_name.lower()
config_file_name = f"{ROOT}{path_separator}{package_name[0]}{path_separator}{package_name}{path_separator}build_info.json"
image_name = "ibmcom/" + package_name + "-ppc64le:" + version.replace('/', '_')

version_key =  None

build_details = {
    'docker_dir' : '',
    'build_script': '',
    'args' : {},
    'docker_command': '',
    'docker_build': True,
    'validate_build_script': True
}


if(os.path.exists(config_file_name)):
    f = open(config_file_name, 'r')
    contents = f.read()
    config_json = json.loads(contents)
    
    build_details['docker_command'] = config_json['docker_cmd'] if 'docker_cmd' in config_json else ''
    build_details['build_script'] = config_json['build_script'] if 'build_script' in config_json else ''
    build_details['docker_build'] = config_json['docker_build'] if 'docker_build' in config_json else True
    build_details['validate_build_script'] = config_json['validate_build_script'] if 'validate_build_script' in config_json else True

    if version not in config_json:
        for key in config_json.keys():
            if version_key:
                break
            sub_keys = [x.strip() for x in key.split(',')]
            if sub_keys:
                if version in sub_keys:
                    version_key = key
                    break
                for sub_key in sub_keys:
                    regex = f"^{sub_key}$"
                    if re.search(regex, version):
                        version_key = key
                        break
    else:
        version_key = version

    version_config = config_json[version_key]

    build_details['docker_dir'] = version_config['dir']
   
    build_args = ''
    if 'patches' in version_config:
        for patch_name in version_config['patches'].keys():
            build_args += f" --build-args {patch_name}={version_config['patches'][patch_name]} "
    if 'args' in version_config:
        for arg_name in version_config['args'].keys():
            build_details['args'][arg_name] = version_config['args'][arg_name]
            build_args += f" --build-args {arg_name}={version_config['args'][arg_name]} "
    
    build_details['docker_command'] = f"sudo docker build -t {image_name}" + (build_args if build_args else '') + (f"-f {version_config['docker_file']}" if 'docker_file' in version_config else '') + f" {build_details['docker_dir']}"
    build_details['build_script'] = (" ".join([f"{x}={build_details['args'][x]}" for x in build_details['args'].keys()])) + " ./" + (version_config['build_script'].strip() if 'build_script' in version_config else build_details['build_script'].strip())

    print(build_details)