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
  local arg="${*}"

  local __ref_var_1_json__=${arg%%=*}
  __ref_var_1_json__="${__ref_var_1_json__#"${__ref_var_1_json__%%[![:space:]]*}"}"
  __ref_var_1_json__="${__ref_var_1_json__%"${__ref_var_1_json__##*[![:space:]]}"}"

  local input=${arg#*=}
  input=${input%%.*}
  input="${input#"${input%%[![:space:]]*}"}"
  input="${input%"${input##*[![:space:]]}"}"

  local path=".${arg#*.}"

#  echo "PARAMETERS: ${__ref_var_1_json__} | ${input} | '${path}'"
#  eval "echo \"INPUT: \$${input}\""

  local result="$(eval "echo \"\$${input}\"" | jq -rc "${path}")"

#  echo "RESULT: ${result}"

  local resultList="("
  local line
  while read -r line; do
    resultList="${resultList} '${line}'"
  done <<< "${result}"
  resultList="${resultList} )"

  eval "${__ref_var_1_json__}=${resultList}"
}
