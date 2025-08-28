import json
import os
import re
 
version = str(os.environ['VERSION'])
match_version = ""
 
# Load build_info.json
with open('build_info.json') as f:
    data = json.load(f)
 
# Collect only version-specific keys (ignore metadata like 'maintainer', etc.)
version_keys = [key for key in data.keys() if re.match(r'^\d+\.\d+.*|\*$', key)]
 
# Sort keys to ensure specific patterns are matched before wildcard '*'
# E.g., "1.7.*" should come before "*"
version_keys.sort(key=lambda k: (k == "*", k))
 
for key in version_keys:
    subKeys = [subKey.strip() for subKey in key.split(',')]
    for subKey in subKeys:
        if subKey == version:
            match_version = key
            break
        # Convert wildcards to regex patterns
        pattern = '^' + re.escape(subKey).replace(r'\*', '.*') + '$'
        if re.fullmatch(pattern, version):
            match_version = key
            break
    if match_version:
        break
 
print(match_version)
