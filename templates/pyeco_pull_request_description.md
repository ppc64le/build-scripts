## Distro Owner PR Review Checklist

- [ ] Confirm PACKAGE_URL points to the correct source.
- [ ] If PACKAGE_URL is a .tar file, automation failed to parse the GitHub link from PyPI. Manually identify the GitHub URL and update the build script.
- [ ] Verify that PACKAGE_VERSION is correctly set in both build-script and build_info.json.
- [ ] Verify that the PACKAGE_URL is the official/canonical source for the package (not a fork/mirror repo).
- [ ] If PACKAGE_URL is incorrect, check PyPI for the correct URL.


## PR Validation Checklist(if required)
- [ ] Remove unnecessary code, incase it happens to update the build-script (rust installation, tox/nox/pytest testing steps)
- [ ] Close the PR if the changes are entirely incorrect
- [ ] Post PR merge, validate the generated wheel
- [ ] Have you checked and followed all the points mentioned in [CONTRIBUTING.MD](https://github.com/ppc64le/build-scripts/blob/master/CONTRIBUTING.md) before raising the PR?
- [ ] Have you validated script on UBI 9 container?
- [ ] Did you run the script(s) on fresh container with `set -e` option enabled and observe success?
- [ ] Create PR to build script repo with required files like license and build_info.json



**Disclaimer:** Auto-generated PRs will be marked as closed if no action is taken before running next weekly scan. Closing auto PRs is a manual activity performed by the Python ecosystem team.
