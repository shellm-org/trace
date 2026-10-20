setup() {
  config_root=$(mktemp -d "${BATS_TMPDIR}/trace-style.XXXXXX")
  export XDG_CONFIG_DIR="${config_root}/config with spaces"
  trace_library="${BATS_TEST_DIRNAME}/../lib/trace.sh"
}

teardown() {
  rm -rf -- "${config_root}"
}

@test "enabling trace without a style file succeeds under errexit" {
  # A fresh configuration must not interrupt a script that exits on errors.
  run bash -ec 'source "$1"; trace --set; trace --unset' bash "${trace_library}"

  [ "${status}" -eq 0 ]
  [ -z "${output}" ]
}

@test "trace reports errors without a style file" {
  run bash -c 'source "$1"; trace --set; false; trace --unset' bash "${trace_library}"

  [ "${status}" -eq 0 ]
  [[ ${output} == *"Traceback (most recent call last):"* ]]
  [[ ${output} == *"Exit/Return code: 1"* ]]
  [[ ${output} != *"No such file or directory"* ]]
}

@test "trace loads an existing custom style" {
  mkdir -p "${XDG_CONFIG_DIR}/shellm/trace"
  printf '%s\n' 'tbTitle="CUSTOM TITLE: "' > "${XDG_CONFIG_DIR}/shellm/trace/style"

  run bash -c 'source "$1"; trace --set; false; trace --unset' bash "${trace_library}"

  [ "${status}" -eq 0 ]
  [[ ${output} == "CUSTOM TITLE: Traceback (most recent call last):"* ]]
}

@test "trace tolerates a missing style file in the default configuration directory" {
  # Use an isolated home so the result does not depend on the user's style.
  run env -u XDG_CONFIG_DIR HOME="${config_root}" bash -ec \
    'source "$1"; trace --set; trace --unset' bash "${trace_library}"

  [ "${status}" -eq 0 ]
  [ -z "${output}" ]
}
