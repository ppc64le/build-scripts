import json
import os
import re
version = str(os.environ['VERSION'])
match_version=""
f = open('build_info.json')
data = json.load(f)
for key,value in data.items():
  subKeys = [subKey.strip() for subKey in key.split(',')]
  if version in subKeys:
    match_version = key
    break
  else:
    for subKey in subKeys:
      regex_str = '^' + subKey.replace(".", "\\.").replace("*", ".*") + '$'
      regex = re.compile(regex_str)
      if regex.match(version):
        match_version = key
  if len(match_version) != 0:
    break
print(match_version)