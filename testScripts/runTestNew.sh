#!/usr/bin/env bash

scriptDir="$(cd "$(dirname "$0")" ; pwd -P )"
projDir="$scriptDir/.."

pushd "${projDir}" > /dev/null

timestamp=$(date +%s)
testRootFolder="reports/test-${timestamp}"
reportFileName="report.csv"

testName="MyTestName"

testConfig='
{
  "scenarioFolderPattern": "${testName}-srt-${srt}-tmt-${tmt}-uc-${uc}-rps-${rps}",
  "scenarioFileNamePattern": "report.csv",
  "fields": [
    {
      "name": "srt",
      "values": [10, 50, 200]
    },
    {
      "name": "tmt",
      "values": [10, 20, 50]
    },
    {
      "name": "uc",
      "values": [2500],
      "type": "one"
    },
    {
      "name": "rps",
      "values": [5000, 6000, 7000, 8000, 9000, 10000]
    },
    {
      "name": "repeateCount",
      "values": [1, 2, 3]
    }
  ]
}
'

#  ,
#  "comand": "${scriptDir}/runScenario.sh --report-folder "${testRootFolder}/${testName}-srt-${srt}-tmt-${tmt}-uc-${uc}-rps-${rps}" \
#                                         --report-filename "${reportFileName}" \
#                                         --service-url "http://localhost:8888" \
#                                         --simulation-class "simulations.${testName}" \
#                                         --ramp-up-duration "20 seconds" \
#                                         --test-duration "5 minutes" \
#                                         --service-response-time "${srt}" \
#                                         --tomcat-max-threads "${tmt}" \
#                                         --user-count "${uc}" \
#                                         --requests-per-second "${rps}""

#function getScenarioFolder {
#  local config="${1}"
#  local values="${2}"
#
#  echo ""
#}
#
#function getJsonArray {
#  echo ""
#}
#
#
#fieldsBase64=( $(echo "${testConfig}" | jq -r '.fields[] | @base64') )
#
#for fieldBase64 in "${fieldsBase64[@]}"; do
#
#  field="$(echo "${fieldBase64}" | base64 --decode)"
#
#  fieldName="$(echo "${field}" | base64 --decode | jq -r '.name')"
#  fieldValues=( $(echo "${field}" | base64 --decode | jq -r '.values[]') )
#
#  echo "new set of data:"
#  echo "${fieldName}"
#  echo "${fieldValues[@]}"
#  echo
#
#  for value in "${fieldValues[@]}"; do
#    echo "value: ${value}"
#  done
#done
#
#exit

function jsonFieldValue {
  local json="${1}"
  local field="${2:-}"

  echo "${json}" | jq -r ".${field}"
}

function jsonArraySize {
  local json="${1}"

  echo "${json}" | jq -r "length"
}

function jsonArrayValue {
  local json="${1}"
  local index="${2:-0}"

  echo "${json}" | jq -r ".[${index}]"
}

fields=$(jsonFieldValue "${testConfig}" "fields")
fieldsSize=$(jsonArraySize "${fields}")
for ((index = 0; index < fieldsSize; index++)); do
  field="$(jsonArrayValue "${fields}" ${index})"
  fieldName="$(jsonFieldValue "${field}" "name")"
  fieldValues="$(jsonFieldValue "${field}" "values")"
  fieldValuesSize=$(jsonArraySize "${fieldValues}")
  for ((valueIndex = 0; valueIndex < fieldValuesSize; valueIndex++)); do
    value="$(jsonArrayValue "${fieldValues}" "${valueIndex}")"
    echo "${fieldName}[${valueIndex}] = ${value}"
  done
  echo
done

echo "================="


echo "${testConfig}" | jq -r '.fields | length'

scenarioFolderPattern="$(jsonFieldValue "${testConfig}" "scenarioFolderPattern")"
echo ${scenarioFolderPattern}

index=0
while : ;do

  field="$(echo "${testConfig}" | jq --argjson index ${index} -r '.fields[$index]')"

  if [[ "${field}" == "null" ]]; then
    break;
  fi

  fieldName="$(echo "${field}" | jq -r '.name')"
  fieldValues=( $(echo "${field}" | jq -rc '.values[]') )

  echo "new set of data:"
  echo "${fieldName}"
  echo "${fieldValues[@]}"
  echo

  for value in "${fieldValues[@]}"; do
    echo "value: ${value}"
    eval "${fieldName}=\"${value}\""

    eval "newName=\"\$${scenarioFolderPattern}\""

    echo ${newName}
  done



  ((index++))
done

#echo "${testConfig}" | jq -r '.fields[0].values'


function jsonXXX {
  local __result=${1}
  local input="${2}"
  local path="${3}"


  local result="$(echo "${input}" | jq -rc "${path}")"

  echo "RESULT IS $result"

  resultList="( "
  while read -r line; do
    resultList="${resultList} '${line}'"
  done <<< "$result"
  resultList="${resultList} )"

  eval "${__result}=${resultList}"

}

# ==================================================================================================
# Usage: json <variable> = <variable>.<field-path>
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



#json name "${testConfig}" '.fields[0].values'
jsonXXX name "${testConfig}" '.fields[0]'

echo ${name[@]}

echo "------------------"

function inside {
  local inVal=""
  jsonXXX inVal "${testConfig}" '.fields[]'

  echo ${inVal}
}

inside

echo ${inVal}
echo ${inVal[@]}

json inVal = testConfig.fields[]

echo ${inVal}
echo ${inVal[@]}

echo "------------------=====------------------"

function loopFields {
  local fields=("${@}")
  local field="${fields[0]}"

  fields=("${fields[@]:1}")

  if [[ "${field}" != "" ]]; then
    local fieldName
    json fieldName = field.name

    local fieldValues=()
    json fieldValues = field.values[]

    local value
    for value in "${fieldValues[@]}"; do
      eval "local ${fieldName}=\"${value}\""

      if [[ "${fields[0]}" != "" ]]; then
        loopFields "${fields[@]}"
      else
        eval "local newName=\"${scenarioFolderPattern}\""
        echo "'${newName}'"
      fi
    done
  fi
}

function runTests {
  local testFields
  json testFields = testConfig.fields[]

  loopFields "${testFields[@]}"
}

testFields="not set"

runTests

echo "${testFields}"

exit













# ==================================================================================================
#  Async test:
# --------------------------------------------------------------------------------------------------
#  declare -a srtList=(10 50 200)
#  declare -a tmtList=(10 20 50)
#  declare -a ucList=(2500)
#  declare -a rpsList=(5000 6000 7000 8000 9000 10000)
#  repeatCount=3
#  testName="AsyncRestThrottled"

# ==================================================================================================
#  Sync test:
# --------------------------------------------------------------------------------------------------
#  declare -a srtList=(10 50 200)
#  declare -a tmtList=(80 120 400 600 1600 2400 6000 10000)
#  declare -a ucList=(2500)
#  declare -a rpsList=(5000 6000 7000 8000 9000 10000)
#  repeatCount=3
#  testName="SyncRestThrottled"
#
# 10 => 100 req | 5000 =>   50 thread
#                 6000 =>   60 thread
#                 7000 =>   70 thread
#                 8000 =>   80 thread
#                 9000 =>   90 thread
#                10000 =>  100 thread
#
# 50 =>  20 req | 5000 =>  250 thread
#                 6000 =>  300 thread
#                 7000 =>  350 thread
#                 8000 =>  400 thread
#                 9000 =>  450 thread
#                10000 =>  500 thread
#
#200 =>   5 req | 5000 => 1000 thread
#                 6000 => 1200 thread
#                 7000 => 1400 thread
#                 8000 => 1600 thread
#                 9000 => 1800 thread
#                10000 => 2000 thread
#
#500 =>   2 req | 5000 => 2500 thread
#                 6000 => 3000 thread
#                 7000 => 3500 thread
#                 8000 => 4000 thread
#                 9000 => 4500 thread
#                10000 => 5000 thread

# ==========================================
# Service response time
# ------------------------------------------
declare -a srtList=(10 50 200)

# ==========================================
# Tomcat max thread
# ------------------------------------------
#declare -a tmtList=(80 400)
#declare -a tmtList=(120 600 2400)
declare -a tmtList=(1600 6000 10000)

# ==========================================
# User count
# ------------------------------------------
declare -a ucList=(2500)

# ==========================================
# Requests per second
# ------------------------------------------
declare -a rpsList=(5000 7000 9000)
#declare -a rpsList=(6000 8000 10000)

# ==========================================
# Repeat count
# ------------------------------------------
repeatCount=3

# ==========================================
# Repeat count
# ------------------------------------------
testName="SyncRestThrottled"

#scenarioFolderPattern="${testRootFolder}/${testName}-srt-${srt}-tmt-${tmt}-uc-${uc}-rps-${rps}"

# ==================================================================================================
#  Build the project:
# --------------------------------------------------------------------------------------------------
mvn clean install

# ==================================================================================================
#  Run the test:
# --------------------------------------------------------------------------------------------------
for srt in "${srtList[@]}"; do
  for tmt in "${tmtList[@]}"; do
    for uc in "${ucList[@]}"; do
      for rps in "${rpsList[@]}"; do
        for ((rc=0; rc<${repeatCount}; rc++)); do
          ${scriptDir}/runScenario.sh --report-folder "${testRootFolder}/${testName}-srt-${srt}-tmt-${tmt}-uc-${uc}-rps-${rps}" \
                                      --report-filename "${reportFileName}" \
                                      --service-url "http://localhost:8888" \
                                      --simulation-class "simulations.${testName}" \
                                      --ramp-up-duration "20 seconds" \
                                      --test-duration "5 minutes" \
                                      --service-response-time "${srt}" \
                                      --tomcat-max-threads "${tmt}" \
                                      --user-count "${uc}" \
                                      --requests-per-second "${rps}"
          sleep 10
        done
      done
    done
  done
done

popd > /dev/null