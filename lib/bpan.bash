# bpan.bash - BPAN Bash Programming Framework
#
# Copyright (c) 2013 Ingy döt Net

#   echo ">>>${PATH//:/$'\n'}<<<" >&2

set -e

[ -z "$BPAN_VERSION" ] || return 0

BPAN_VERSION='0.0.1'

@() { echo "$@"; }
bpan:export:std() { @ use die warn; }

# Source a bash library call import on it:
bpan:use() {
  local library_name="${1:?bpan:use requires library name}"; shift
  local library_path="$(bpan:findlib $library_name)"
  [ -n "$library_path" ] || {
    bpan:die "Can't find library '$library_name'." 1
  }
  source "$library_path"
  if bpan:can "$library_name:import"; then
    "$library_name:import" "$@"
  else
    bpan:import "$@"
  fi
}

# Copy bpan: functions to unprefixed functions
bpan:import() {
  local arg=
  for arg; do
    if [[ "$arg" =~ ^: ]]; then
      bpan:import `bpan:export$arg`
    else
      bpan:fcopy bpan:$arg $arg
    fi
  done
}

# Function copy
bpan:fcopy() {
  bpan:can "${1:?bpan:fcopy requires an input function name}" ||
    bpan:die "'$1' is not a function" 2
  local func=$(type "$1" 3>/dev/null | tail -n+3)
  [ -n "$3" ] && "$3"
  eval "${2:?bpan:fcopy requires an output function name}() $func"
}

# Find the path of a library
bpan:findlib() {
  local library_name="$(tr [A-Z] [a-z] <<< "${1//:://}").bash"
  find ${BPANLIB//:/ } -name ${library_name##*/} 2>/dev/null |
    grep -E "$library_name\$" |
    head -n1
}

bpan:die() {
  local msg="${1:-Died}"
  printf "${msg//\\n/$'\n'}" >&2
  local trailing_newline_re=$'\n''$'
  [[ "$msg" =~ $trailing_newline_re ]] && exit 1

  local c=($(caller ${DIE_STACK_LEVEL:-${2:-0}}))
  [ ${#c[@]} -eq 2 ] &&
    msg=" at line %d of %s" ||
    msg=" at line %d in %s of %s"
  printf "$msg\n" ${c[@]} >&2
  exit 1
}

bpan:warn() {
  local msg="${1:-Warning}"
  printf "${msg//\\n/$'\n'}\n" >&2
}

bpan:can() {
  [ "$(type -t "${1:?bpan:can requires a function name}")" == function ]
}
