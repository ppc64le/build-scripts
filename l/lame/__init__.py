import os
import sys
import subprocess

def lameCLI():
    package_dir = os.path.dirname(__file__)
    lame_path = os.path.join(package_dir, 'bin', 'lame')
    if not os.path.exists(lame_path):
        print('lame binary not found')
        sys.exit(1)
    subprocess.run([lame_path] + sys.argv[1:], check=True)
lameCLI()
