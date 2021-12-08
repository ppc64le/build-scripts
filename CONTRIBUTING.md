## A special note to contributors

Please follow the below rules while contributing your build script to this repo.

1. Please mention in notes that, whether the script is made for root user or non-root user.
2. Always keep the package version/commitID in variable. Try to take version as parameter otherwise take a default version number you are working on. Below is the example:
	``` shell
	VERSION=${1:-v5.0.2}
	# v5.0.2 is the default version, in case of no parameter passed to the script.
	```
3. Check if package/component directory already exists and add new file into it. If not, create a directory for new package/component and place LICENSE file into it.
4. Package name & Filenames must be in **lowercase**.
5. Get Legal approvals incase of any code change/patch. 
6. Build script templates can be found [here](https://github.com/ppc64le/build-scripts/tree/master/templates).
7. Test the build script on clean UBI container before raising PR. Include test logs as part of PR.
8. Try to create a branch on your forked repo for each PR.
