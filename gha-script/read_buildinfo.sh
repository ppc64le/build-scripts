#!/bin/bash -e

package_name=$(echo $PACKAGE_NAME | tr '[:upper:]' '[:lower:]')
image_name="icr.io/ppc64le-oss/$package_name-ppc64le:$VERSION"
initial_char=${package_name:0:1}
package_dirpath="$initial_char/$package_name/"
buildinfo_path=$package_dirpath'build_info.json'
match_version=$VERSION

if [ -f $buildinfo_path ]; then
  echo "$package_dirpath exists"

else
  package_dirpath="$initial_char/$PACKAGE_NAME/"
  echo "Correct package_dirpath is $package_dirpath"
fi

CUR_DIR=$(pwd)
cd $package_dirpath
echo "printing the list of contents"
pwd
ls -ltr


config_file='build_info.json'
if [ -f $config_file ]; then
  jsonObj=$config_file
  build_script=$(jq .build_script $jsonObj)

  if $(jq 'has("use_non_root_user")' $jsonObj); then
    nonRootBuild=$(jq .use_non_root_user $jsonObj)
  fi

  # default build_docker=true
  build_docker=true
  if $(jq 'has("docker_build")' $jsonObj); then
    build_docker=$(jq .docker_build $jsonObj)
  fi


  # default validate_build_script=true
  validate_build_script=true
  if $(jq 'has("validate_build_script")' $jsonObj); then
    validate_build_script=$(jq .validate_build_script $jsonObj)
  fi

  echo "Checking for string/pattern match for version in build_info.json"

  if [[ $(jq --arg ver "$VERSION" '.[$ver]' $config_file) == null ]]; then
    # Using Python script to find matched version string/key in build_info.json
    match_version=$(python $CUR_DIR/gha-script/match_version_buildinfo.py)
    echo "match_version = $match_version"
  fi

  # Getting specific build_script name and other overrides for version
  if [[ $(jq --arg ver "$match_version" '.[$ver]' $config_file) != null ]]; then
    version_block=".[\"$match_version\"]"  # Properly quoted key for jq

    # version-specific build_script (may be a string or a list)
    if [[ $(jq -r "$version_block.build_script" $config_file) != "null" ]]; then
      build_script=$(jq -c "$version_block.build_script" $config_file)
    fi

    # version-specific base_docker_image
    if [[ $(jq -r "$version_block.base_docker_image" $config_file) != "null" ]]; then
      basename=$(jq -r "$version_block.base_docker_image" $config_file)
    fi

    # version-specific base_docker_variant
    if [[ $(jq -r "$version_block.base_docker_variant" $config_file) != "null" ]]; then
      variant_str=$(jq -r "$version_block.base_docker_variant" $config_file)
      case "$variant_str" in
        "rhel") variant=1 ;;
        "ubuntu") variant=2 ;;
        "alpine") variant=3 ;;
        *)
          echo "No valid distro variant, picking default one"
          variant=1 ;;
      esac
    fi

    # version-specific use_non_root_user
    if [[ $(jq "$version_block | has(\"use_non_root_user\")" $config_file) == "true" ]]; then
      nonRootBuild=$(jq "$version_block.use_non_root_user" $config_file)
    fi

    # version-specific validate_build_script
    if [[ $(jq "$version_block | has(\"validate_build_script\")" $config_file) == "true" ]]; then
      validate_build_script=$(jq "$version_block.validate_build_script" $config_file)
    fi

    # version-specific docker_build
    if [[ $(jq "$version_block | has(\"docker_build\")" $config_file) == "true" ]]; then
      build_docker=$(jq "$version_block.docker_build" $config_file)
    fi
  fi
fi



# ---------------------------------------------------------------------------
# Helper: read "# Tested on" from a single build script file.
# Normalises the raw value: strip spaces, uppercase, collapse "UBI : 9.3" ->
# "UBI:9.3" so downstream consumers see a consistent format.
# Usage:  tested_on=$(read_tested_on "path/to/script.sh")
# ---------------------------------------------------------------------------
read_tested_on() {
  local script_file="$1"
  local value=""
  if [ -f "$script_file" ]; then
    while IFS= read -r line; do
      if [[ "$line" == "# Tested on"* ]]; then
        # Extract everything after the first colon, strip outer whitespace,
        # uppercase, then collapse spaces around colons (e.g. "UBI : 9.3" -> "UBI:9.3")
        value=$(echo "$line" | cut -d ':' -f 2- \
          | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' \
          | tr '[:lower:]' '[:upper:]' \
          | sed 's/[[:space:]]*:[[:space:]]*/:/g')
        break
      fi
    done < "$script_file"
  fi
  echo "$value"
}

# ---------------------------------------------------------------------------
# Build the BUILD_SCRIPTS_JSON array and set the single-script compat vars.
#
# build_script in build_info.json can be:
#   - a string : "pytorch_ubi_9.3.sh"
#   - a list   : ["pytorch_ubi_8.3.sh", "pytorch_ubi_9.3.sh", "pytorch_ubi_10.3.sh"]
#
# For both cases we produce:
#   BUILD_SCRIPTS_JSON   -  compact JSON array of {script, tested_on} objects,
#                         consumed by the GHA matrix via fromJson().
#   BUILD_SCRIPT         -  backward-compat: first (or only) script filename.
#   TESTED_ON            -  backward-compat: first (or only) tested_on value.
#
# NOTE: '# Tested on' is MANDATORY in every build script. The pipeline will
#       abort if it is missing  -  there is no default fallback.
# ---------------------------------------------------------------------------

# Derive type from the already-resolved $build_script shell variable.
# This is correct whether build_script came from the top-level field or
# was overridden by a version block  -  both paths store the final value in
# $build_script as either a bare filename string or a compact JSON array.
script_type=$(echo "$build_script" | jq -r 'type' 2>/dev/null || echo "string")
echo "build_script type (resolved): $script_type"

BUILD_SCRIPTS_JSON=""

if [ "$script_type" = "array" ]; then
  echo "build_script is a list  -  iterating each entry to read its '# Tested on' value"

  json_array="["
  first=true
  first_script=""
  first_tested_on=""

  # jq outputs one bare filename per line (no surrounding quotes)
  while IFS= read -r script_name; do
    # strip any stray quotes/whitespace that jq might leave
    script_name=$(echo "$script_name" | tr -d '"' | xargs)
    [ -z "$script_name" ] && continue

    raw_tested_on=$(read_tested_on "$script_name")

    if [ -z "$raw_tested_on" ]; then
      echo "ERROR: '# Tested on' header is missing in '$script_name'."
      echo "   Every build script must declare the UBI version it targets, e.g.:"
      echo "   # Tested on UBI:9.3"
      exit 1
    fi

    echo "  script='$script_name'  tested_on='$raw_tested_on'"

    # Record first entry for backward-compat single-value exports
    if [ "$first" = "true" ]; then
      first_script="$script_name"
      first_tested_on="$raw_tested_on"
      first=false
    fi

    # Append JSON object  -  jq --arg safely escapes both values
    entry=$(jq -n \
      --arg s "$script_name" \
      --arg t "$raw_tested_on" \
      '{"script":$s,"tested_on":$t}')

    if [ "$json_array" = "[" ]; then
      json_array="${json_array}${entry}"
    else
      json_array="${json_array},${entry}"
    fi

  # Iterate the resolved $build_script variable (not the file) so that
  # version-block overrides are respected.
  done < <(echo "$build_script" | jq -r '.[]')

  json_array="${json_array}]"
  BUILD_SCRIPTS_JSON="$json_array"

  # Backward-compat single values  -  point to the first entry in the list
  build_script="$first_script"
  tested_on="$first_tested_on"

else
  # Single string  -  existing behaviour
  build_script_with_quotes=$build_script
  stripped_build_script=$(echo "$build_script_with_quotes" | sed 's/"//g')
  echo "build_script (single): $stripped_build_script"

  tested_on=$(read_tested_on "$stripped_build_script")

  if [ -z "$tested_on" ]; then
    echo "ERROR: '# Tested on' header is missing in '$stripped_build_script'."
    echo "   Every build script must declare the UBI version it targets, e.g.:"
    echo "   # Tested on UBI:9.3"
    exit 1
  fi
  echo "Tested on value: $tested_on"

  # Wrap single entry into the same JSON array format for consistency
  BUILD_SCRIPTS_JSON=$(jq -n \
    --arg s "$stripped_build_script" \
    --arg t "$tested_on" \
    '[{"script":$s,"tested_on":$t}]')

  # Backward-compat: strip quotes from the jq-extracted string value
  build_script="$stripped_build_script"
fi

echo "BUILD_SCRIPTS_JSON: $BUILD_SCRIPTS_JSON"

# ---------------------------------------------------------------------------
# Bucket scripts by UBI major version -> SCRIPT_UBI8, SCRIPT_UBI9, SCRIPT_UBI10.
# Each is a single {script, tested_on} JSON object (or empty string "").
# At most one script per UBI major version is expected per package.
# Callers (currency-build.yaml, pr-build.yaml) use these to drive named jobs:
#   build_ubi8 / build_ubi9 / build_ubi10
#   wheel_build_ubi8_pyXXX / wheel_build_ubi9_pyXXX / wheel_build_ubi10_pyXXX
# ---------------------------------------------------------------------------
SCRIPT_UBI8=""
SCRIPT_UBI9=""
SCRIPT_UBI10=""

while IFS= read -r entry; do
  [ -z "$entry" ] && continue
  t_on=$(echo "$entry" | jq -r '.tested_on')
  # Normalise: uppercase, collapse separators around UBI, then extract the
  # integer immediately following "UBI".  Uses only sed + tr (POSIX)  -  no
  # grep -P needed, so it works on ppc64le runners where grep -P is absent.
  t_upper=$(echo "$t_on" | tr '[:lower:]' '[:upper:]')
  # Collapse "UBI : 9.3" / "UBI:9.3" / "UBI 9.3" / "UBI9.3" -> "UBI9.3"
  t_norm=$(echo "$t_upper" | sed 's/UBI[[:space:]]*[: ][[:space:]]*/UBI/g')
  # Extract digits immediately after "UBI"  e.g. "UBI10.0" -> "10"
  major=$(echo "$t_norm" | sed 's/.*UBI\([0-9][0-9]*\).*/\1/')
  # If sed left non-numeric content (no UBI match), clear it
  case "$major" in
    ''|*[!0-9]*) major="" ;;
  esac
  echo "  bucket: tested_on='$t_on'  major='$major'"
  case "$major" in
    8)  SCRIPT_UBI8="$entry"  ;;
    9)  SCRIPT_UBI9="$entry"  ;;
    10) SCRIPT_UBI10="$entry" ;;
    *)  echo "WARNING: Unknown UBI major '$major' in tested_on='$t_on'  -  skipping bucket" ;;
  esac
done < <(echo "$BUILD_SCRIPTS_JSON" | jq -c '.[]')

echo "SCRIPT_UBI8:  $SCRIPT_UBI8"
echo "SCRIPT_UBI9:  $SCRIPT_UBI9"
echo "SCRIPT_UBI10: $SCRIPT_UBI10"

# Extract auditwheel exclusions (unchanged  -  same pattern as before)
AUDITWHEEL_EXCLUDE=""
if jq -e 'has("auditwheel_exclude")' "$config_file" >/dev/null; then
  AUDITWHEEL_EXCLUDE=$(jq -r '.auditwheel_exclude | join(" ")' "$config_file")
fi

# ---------------------------------------------------------------------------
# Write variable.sh
# JSON objects are single-quote-wrapped so embedded double-quotes survive.
# ---------------------------------------------------------------------------
echo "export VERSION=\"$VERSION\""                                > $CUR_DIR/variable.sh
echo "export BUILD_SCRIPT=\"$build_script\""                     >> $CUR_DIR/variable.sh
echo "export PKG_DIR_PATH=\"$package_dirpath\""                  >> $CUR_DIR/variable.sh
echo "export IMAGE_NAME=\"$image_name\""                         >> $CUR_DIR/variable.sh
echo "export VARIANT=\"$variant\""                               >> $CUR_DIR/variable.sh
echo "export BASENAME=\"$basename\""                             >> $CUR_DIR/variable.sh
echo "export NON_ROOT_BUILD=\"$nonRootBuild\""                   >> $CUR_DIR/variable.sh
echo "export TESTED_ON=\"$tested_on\""                           >> $CUR_DIR/variable.sh
echo "export AUDITWHEEL_EXCLUDE=\"$AUDITWHEEL_EXCLUDE\""         >> $CUR_DIR/variable.sh
# Full array  -  kept for any downstream consumer that still needs it
echo "export BUILD_SCRIPTS_JSON='$BUILD_SCRIPTS_JSON'"       >> $CUR_DIR/variable.sh
# Per-UBI-major named exports  -  empty string when that UBI version has no script
echo "export SCRIPT_UBI8='$SCRIPT_UBI8'"                    >> $CUR_DIR/variable.sh
echo "export SCRIPT_UBI9='$SCRIPT_UBI9'"                    >> $CUR_DIR/variable.sh
echo "export SCRIPT_UBI10='$SCRIPT_UBI10'"                  >> $CUR_DIR/variable.sh

chmod +x $CUR_DIR/variable.sh
cat $CUR_DIR/variable.sh
cd $CUR_DIR
