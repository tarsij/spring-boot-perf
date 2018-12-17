#!/usr/bin/env bash

# ==================================================================================================
#  json
#  ------------------------------
#  - usage: json <variable> = <variable>.<field-path>
#
#  - executes an operation on a string containing a json
#  - behind the scenes it is using the 'jq' tool
#  - returns a bash array of json strings
#    if the return type is a string / array of strings then the string is unquoted
# --------------------------------------------------------------------------------------------------
function json {
  local __json_arg="${*}"

  local __json_varName=${__json_arg%%=*}
  __json_varName="${__json_varName#"${__json_varName%%[![:space:]]*}"}"
  __json_varName="${__json_varName%"${__json_varName##*[![:space:]]}"}"

  local __json_input=${__json_arg#*=}
  __json_input=${__json_input%%.*}
  __json_input="${__json_input#"${__json_input%%[![:space:]]*}"}"
  __json_input="${__json_input%"${__json_input##*[![:space:]]}"}"

  local __json_path=".${__json_arg#*.}"

  #echo "PARAMETERS: ${__json_varName} | ${__json_input} | '${__json_path}'" > /dev/tty
  #eval "echo \"INPUT: \$${__json_input}\"" > /dev/tty

  local __json_result="$(eval "echo \"\$${__json_input}\"" | jq -rc "${__json_path}")"

  #echo "RESULT: ${__json_result}" > /dev/tty

  local __json_resultList="("
  local __json_line
  while read -r __json_line; do
    __json_resultList="${__json_resultList} $'${__json_line//\'/\'}'"
  done <<< "${__json_result}"
  __json_resultList="${__json_resultList} )"

  #echo "  RESULT LIST: ${__json_resultList}" > /dev/tty

  eval "${__json_varName}=${__json_resultList}"
}

# --------------------------------------------------------------------------------------------------
