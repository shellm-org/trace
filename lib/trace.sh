
__trace_trim_string() {
    # Usage: trim_string "   example   string    "
    : "${1#"${1%%[![:space:]]*}"}"
    : "${_%"${_##*[![:space:]]}"}"
    printf '%s\n' "$_"
}

__trace_get_line() {
  __trace_trim_string "$(tail -n+$2 "$1" | head -n1)"
}

__trace_eval() {
  local old_trace_maxlvl=${TRACE_MAXLVL}
  TRACE_MAXLVL=3
  __trace_eval_input=("$@")
  command eval "$@"
  unset __trace_eval_input
  TRACE_MAXLVL=${old_trace_maxlvl}
}

trace() {
  case "$1" in
    --set)
      set -E
      # unset __TRACEBACKS
      # declare -a __TRACEBACKS
      . "${XDG_CONFIG_DIR:-${HOME}/.config}"/shellm/trace/style
      eval() { __trace_eval "$@"; }
      trap '__trace_code=$?; __trace_command=${BASH_COMMAND}; trace' ERR
      return 0
    ;;
    --unset)
      set +E
      # unset __TRACEBACKS
      unset -f eval
      trap - ERR
      return 0
    ;;
  esac

  local i l
  local record
  local source
  local func
  local lineno
  local prevsrc
  local seen_main
  local seen_source
  local max_lvl

  prevsrc=""
  record=""
  l=${#BASH_LINENO[@]}

  echo -ne "${tbTitle}Traceback (most recent call last):${tbReset}"

  (( l == 2 )) && max_lvl=1 || max_lvl=${TRACE_MAXLVL:-2}

  for (( i=l-1; i>=max_lvl; i-- )); do

    source="${BASH_SOURCE[i]}"
    func="${FUNCNAME[i]}"
    lineno="${BASH_LINENO[i-1]}"

    if [ "${source}" != "${prevsrc}" ]; then
      prevsrc="${source}"
      seen_source=0
    fi

    line="$(__trace_get_line "${source}" ${lineno})"

    printf "\n  ${tbMain}File \"${tbFile}${source}${tbMain}\", line ${tbLineno}${lineno}${tbMain}, in ${tbFunction}"

    case "${func}" in
      main|source)
        if (( seen_${func} == 0 )); then
          declare seen_$func=1
          echo -n "<${func}>"
        else
          echo -n "${func}"
        fi
      ;;
      *) echo -n "${func}" ;;
    esac
    echo -e "${tbMain}"

    printf "    ${tbLine}%s${tbReset}" "${line}"

  done

  if [ "${line}" != "${__trace_command}" ] && [ -n "${__trace_command}" ]; then
    if [[ ${__trace_command} =~ $'\n' ]]; then
      printf "\n     "
    fi
    printf " ${tbMain}(${tbCommand}${__trace_command//$'\n'/$'\n'       }${tbMain})${tbReset}"
  fi

  if [ -n "${__trace_code}" ]; then
    printf "\n  ${tbCode}Exit/Return code: ${__trace_code}${tbReset}\n"
  fi
  echo

  unset __trace_code
  unset __trace_command
}

# __trace_record() {
#   __TRACEBACKS+=("$(__trace_get)")
# }

# __trace_record_and_print() {
#   local tb="$(__trace_get)"
#   __TRACEBACKS+=("${tb}")
#   echo "${tb}" >&2
# }

# __trace_print_recorded() {
#   local tb
#   for tb in "${__TRACEBACKS[@]}"; do
#     echo "${tb}"
#     echo
#   done
# }

__trace_set() {
  TRACE_MAXLVL=1
  trace --set
}

__trace_unset() {
  unset TRACE_MAXLVL
  trace --unset
}


SHELLM_HOOKS_SOURCE_START+=(__trace_set)
SHELLM_HOOKS_SOURCE_END+=(__trace_unset)
