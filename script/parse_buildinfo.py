import re
import os

def find_matching_version(jsonObj, version):
    for entry in jsonObj:
        key = entry
        subKeys = [subKey.strip() for subKey in key.split(',')]
        if version in subKeys:
            version = key
            print (f"BREAK1 {version}")
            return version
        else:
            for subKey in subKeys:
                regex_str = '^' + subKey.replace(".", "\\.").replace("*", ".*") + '$'
                regex = re.compile(regex_str)
                if regex.match(version):
                    version = key
                    print (f"BREAK2 {version}")
                    return version

input_version = str(os.environ['VERSION'])
input_jsonObj = os.environ['jsonObj']
result_version = find_matching_version(input_jsonObj, input_version)
print(f"BREAK3 {result_version}")