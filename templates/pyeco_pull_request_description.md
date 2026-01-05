## Distro Owner PR Review Checklist
* [ ] Confirm that `PACKAGE_URL` points to the correct source — it should be a GitHub repository link. If not, identify the correct GitHub source and update the build script accordingly (follow the steps provided in the **PR Validation Process**).
  **Note:** `PACKAGE_URL` should never be a `.tar` archive link.
* [ ] Confirm that the `PACKAGE_VERSION` matches the version required by your project.
* [ ] Check if any additional configuration is needed to install the package from source that is not present in the current PR.
* [ ] Optionally, validate the script using the steps outlined below.

## PR Validation Process
* Use a **ppc64le** VM with at least **8 GB RAM** (more is recommended, as insufficient RAM may cause random build failures).
* Run the `<package-name>.sh` script provided in this PR inside a fresh **UBI 9.3** container (i.e., `sh <package-name>.sh`).
* Ensure that the build script execution ends with a message like:
  **"Pass | Both\_Install\_and\_Test\_Success"**
* If the build script fails and you identify a fix required in the `<package-name>.sh` script to achieve successful execution, follow these steps:

  * Fork the [build-scripts repo](https://github.com/ppc64le/build-scripts)
  * Create a new branch for your changes, starting from the version proposed in this PR
  * Follow all the points mentioned in [CONTRIBUTING.MD](https://github.com/ppc64le/build-scripts/blob/master/CONTRIBUTING.md) before raising the PR
  * Open a new PR from your fork with the fix
  * Close this auto-generated PR and include a link to your updated PR in the closure comment

**Disclaimer:** Auto-generated PRs will be marked as **closed** if no action is taken before the next weekly scan. Closing auto PRs is a manual task performed by the Python ecosystem team.
