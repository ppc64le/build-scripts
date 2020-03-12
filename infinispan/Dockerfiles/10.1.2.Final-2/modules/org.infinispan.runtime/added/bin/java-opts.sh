#!/bin/sh
# ===================================================================================
# Generic startup script for running arbitrary Java applications with
# being optimized for running in containers
#
# Modified version of https://github.com/fabric8io-images/run-java-sh/blob/master/fish-pepper/run-java-sh/fp-files/run-java.sh
# ===================================================================================

if [ -n "${DEBUG:-}" ]; then
  set -x
fi

# ksh is different for defining local vars
if [ -n "${KSH_VERSION:-}" ]; then
  alias local=typeset
fi

# Generic formula evaluation based on awk
calc() {
  local formula="$1"
  shift
  echo "$@" | awk '
    function ceil(x) {
      return x % 1 ? int(x) + 1 : x
    }
    function log2(x) {
      return log(x)/log(2)
    }
    function max2(x, y) {
      return x > y ? x : y
    }
    function round(x) {
      return int(x + 0.5)
    }
    {print '"int(${formula})"'}
  '
}

max_memory() {
  # High number which is the max limit until which memory is supposed to be
  # unbounded.
  local mem_file="/sys/fs/cgroup/memory/memory.limit_in_bytes"
  if [ -r "${mem_file}" ]; then
    local max_mem_cgroup="$(cat ${mem_file})"
    local max_mem_meminfo_kb="$(cat /proc/meminfo | awk '/MemTotal/ {print $2}')"
    local max_mem_meminfo="$(expr $max_mem_meminfo_kb \* 1024)"
    if [ ${max_mem_cgroup:-0} != -1 ] && [ ${max_mem_cgroup:-0} -lt ${max_mem_meminfo:-0} ]
    then
      echo "${max_mem_cgroup}"
    fi
  fi
}

init_limit_env_vars() {
  # Read in container limits and export the as environment variables
  local mem_limit="$(max_memory)"
  if [ -n "${mem_limit}" ]; then
    export CONTAINER_MAX_MEMORY="${mem_limit}"
  fi
}

# ==========================================================================
# Check for memory options and set max heap size if needed
calc_max_memory() {
  # Check whether -Xmx is already given in JAVA_OPTIONS
  if echo "${JAVA_OPTIONS:-}" | grep -q -- "-Xmx"; then
    return
  fi

  if [ -z "${CONTAINER_MAX_MEMORY:-}" ]; then
    return
  fi

  # Check for the 'real memory size' and calculate Xmx from the ratio
  if [ -n "${JAVA_MAX_MEM_RATIO:-}" ]; then
    if [ "${JAVA_MAX_MEM_RATIO}" -eq 0 ]; then
      # Explicitely switched off
      return
    fi
    calc_mem_opt "${CONTAINER_MAX_MEMORY}" "${JAVA_MAX_MEM_RATIO}" "mx"
  fi
  # When JAVA_MAX_MEM_RATIO not set and JVM >= 10 no max_memory
}

# Check for memory options and set initial heap size if requested
calc_init_memory() {
  # Check whether -Xms is already given in JAVA_OPTIONS.
  if echo "${JAVA_OPTIONS:-}" | grep -q -- "-Xms"; then
    return
  fi

  # Check if value set
  if [ -z "${JAVA_INIT_MEM_RATIO:-}" ] || [ -z "${CONTAINER_MAX_MEMORY:-}" ] || [ "${JAVA_INIT_MEM_RATIO}" -eq 0 ]; then
    return
  fi

  # Calculate Xms from the ratio given
  calc_mem_opt "${CONTAINER_MAX_MEMORY}" "${JAVA_INIT_MEM_RATIO}" "ms"
}

calc_mem_opt() {
  local max_mem="$1"
  local fraction="$2"
  local mem_opt="$3"

  local val=$(calc 'round($1*$2/100/1048576)' "${max_mem}" "${fraction}")
  echo "-X${mem_opt}${val}m"
}

# Switch on diagnostics except when switched off
diagnostics_options() {
  if [ -n "${JAVA_DIAGNOSTICS:-}" ]; then
    echo "-XX:NativeMemoryTracking=summary -Xlog:gc*:stdout:time -XX:+UnlockDiagnosticVMOptions"
  fi
}

gc_options() {
  local gc_options="-XX:+ExitOnOutOfMemoryError"
  if [ -n "${JAVA_GC_METASPACE_SIZE:-}" ] || [ "${JAVA_GC_METASPACE_SIZE//[!0-9]/}" -gt 0 ]; then
    gc_options="${gc_options} -XX:MetaspaceSize=${JAVA_GC_METASPACE_SIZE}"
  fi

  if [ -n "${JAVA_GC_MAX_METASPACE_SIZE:-}" ] || [ "${JAVA_GC_MAX_METASPACE_SIZE//[!0-9]/}" -gt 0 ]; then
    gc_options="${gc_options} -XX:MaxMetaspaceSize=${JAVA_GC_MAX_METASPACE_SIZE}"
  fi
  echo ${gc_options}
}

java_opts() {
  init_limit_env_vars
  # Echo options, trimming trailing and multiple spaces
  echo "${JAVA_OPTIONS:-} $(calc_init_memory) $(calc_max_memory) $(diagnostics_options) $(gc_options)" | awk '$1=$1'
}
