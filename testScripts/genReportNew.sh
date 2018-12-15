#!/usr/bin/env bash

scriptDir="$(cd "$(dirname "$0")" ; pwd -P )"
projDir="$scriptDir/.."

# source ${scriptDir}/common.sh

# Defaults

htmlReportName="report.html"

declare -a colors=('255, 99, 132' '54, 162, 235' '255, 206, 86' '75, 192, 192' '153, 102, 255' '255, 159, 64')

reportFolder="reports/test-async"
reportFileName="report.csv"

testName="AsyncRestThrottled"
reportFolderFormat="${testName}-srt-%s-tmt-%s-uc-%s-rps-%s"

declare -a srtList=(10 50 200)
declare -a tmtList=(10 20 50)
declare -a ucList=(2000 2500)
declare -a rpsList=(5000 6000 7000 8000 9000 10000)


#testRootFolder="reports/test-sync"
#reportFileName="report.csv"
#
#testName="SyncRestThrottled"
#reportFolderFormat="${testName}-srt-%s-tmt-%s-uc-%s-rps-%s"
#
#declare -a srtList=(10 50 200)
#declare -a tmtList=(120 600 2400)
#declare -a ucList=(2500)
#declare -a rpsList=(5000 7000 9000)

declare -a fieldList=("Req/s|mean_rps|Mean RPS @ no. of threads"
                      "Mean|mean_response_time|Mean response time @ no. of threads"
                      "Failed|error|Errors @ no. of threads"
                      "95th|95th_percentile|95th percentile @ no. of threads"
                      "99th|99th_percentile|99th percentile @ no. of threads"
                      "Max|max_percentile|Max percentile @ no. of threads"
                      "Peak|peak_threads|Peak threads @ no. of threads"
                      )

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

# ##################################################################################################

function fieldName {
  local field="${1}"
  local separator="${2:-|}"

  field="${field%%\|*}"
  echo "${field}"
}

function fieldScriptName {
  local field="${1}"
  local separator="${2:-|}"

  field="${field#*\|}"
  field="${field%\|*}"
  echo "${field}"
}

function fieldReportName {
  local field="${1}"
  local separator="${2:-|}"

  field="${field##*\|}"
  echo "${field}"
}

# ##################################################################################################

function joinValues {
  local IFS="$1"

  shift
  echo "$*"
}

# ##################################################################################################

function float2Milli {
  local value="${1:-0}"

  valueD=${value%%.*}
  if [[ "${value}" == *"."* ]]; then
    valueP=${value##*.}
  else
    valueP=""
  fi
  valueP=${valueP}000
  valueP=${valueP:0:3}
  echo "${valueD}${valueP}"
}

# --------------------------------------------------------------------------------------------------

function milli2Float {
  local value="${1:-0}"
  local negative=""

  if [[ ${value} -lt 0 ]]; then
    negative="-"
    ((value=-value))
  fi

  local valueD=${value}
  local valueP=${value}

  ((valueD/=1000))
  ((valueP-=valueD*1000))

  if [[ "${valueP}" == "0" ]]; then
    echo "${negative}${valueD}"
  else
    valueP=$(printf %03d ${valueP})
    valueP=${valueP%00}
    valueP=${valueP%0}
    echo "${negative}${valueD}.${valueP}"
  fi
}

# --------------------------------------------------------------------------------------------------

function floatSum {
  local value1=$(float2Milli ${1:-0})
  local value2=$(float2Milli ${2:-0})

  ((value1+=value2))

  echo "$(milli2Float ${value1})"
}

# --------------------------------------------------------------------------------------------------

function floatSub {
  local value1=$(float2Milli ${1:-0})
  local value2=$(float2Milli ${2:-0})

  ((value1-=value2))

  echo "$(milli2Float ${value1})"
}

# --------------------------------------------------------------------------------------------------

function floatDiv {
  local value1=$(float2Milli $(float2Milli ${1:-0}))
  local value2=$(float2Milli ${2:-0})

  ((value1/=value2))

  echo "$(milli2Float ${value1})"
}

# --------------------------------------------------------------------------------------------------

function floatMul {
  local value1=$(float2Milli ${1:-0})
  local value2=$(float2Milli ${2:-0})

  ((value1*=value2))

  value1=$(milli2Float ${value1})
  echo "$(milli2Float ${value1%%.*})"
}

# ##################################################################################################

function tableStart {
  echo "    <div class=\"divTable\">"
}

# --------------------------------------------------------------------------------------------------

function tableEnd {
  echo "    </div>"
}

# --------------------------------------------------------------------------------------------------

function tableHeadingStart {
  echo "      <div class=\"divTableHeading\">"
}

# --------------------------------------------------------------------------------------------------

function tableHeadingEnd {
  echo "      </div>"
}

# --------------------------------------------------------------------------------------------------

function tableColumnHead {
  local content=${1}

  echo "          <div class=\"divTableHead\">"
  echo "            ${content}"
  echo "          </div>"
}

# --------------------------------------------------------------------------------------------------

function tableBodyStart {
  echo "      <div class=\"divTableBody\">"
}

# --------------------------------------------------------------------------------------------------

function tableBodyEnd {
  echo "      </div>"
}

# --------------------------------------------------------------------------------------------------

function tableRowStart {
  echo "        <div class=\"divTableRow\">"
}

# --------------------------------------------------------------------------------------------------

function tableRowEnd {
  echo "        </div>"
}

# --------------------------------------------------------------------------------------------------

function firstColumn {
  local content=${1}

  echo "          <div class=\"divTableFirst\">"
  echo "            ${content}"
  echo "          </div>"
}

# --------------------------------------------------------------------------------------------------

function declareCanvas {
  local nameSpec=${1}
  local width=${2:-400}
  local height=${3:-250}

  echo "          <div class=\"divTableCell\">"
  echo "            <canvas class=\"chart\" id=\"myChart_${nameSpec}\" width=\"${width}\" height=\"${height}\"></canvas>"
  echo "          </div>"
}

# ##################################################################################################

function chartScriptStart {
  echo "    <script>"
}

# --------------------------------------------------------------------------------------------------

function chartScriptEnd {
  echo "    </script>"
}

# --------------------------------------------------------------------------------------------------

function chartStart {
  local nameSpec=${1}

  echo "      var ctx_${nameSpec} = document.getElementById(\"myChart_${nameSpec}\").getContext('2d');"
  echo "      new Chart(ctx_${nameSpec}, {"
  echo "        type: 'line',"
  echo "        data: {"
}

# --------------------------------------------------------------------------------------------------

function chartEnd {
  echo "        },"
  echo "        options: {"
  echo "          responsive: false,"
  echo "          scales: {"
  echo "            yAxes: [{"
  echo "              ticks: {"
  echo "                beginAtZero:true"
  echo "              }"
  echo "            }]"
  echo "          },"
  echo "          legend: {"
  echo "            position: 'right'"
  echo "          }"
  echo "        }"
  echo "      });"
}

# --------------------------------------------------------------------------------------------------

function chartLabels {
  local labels="${1}"
  echo "          labels: [${labels}],"
}

# --------------------------------------------------------------------------------------------------

function chartDatasetsStart {
  echo "          datasets: ["
}

# --------------------------------------------------------------------------------------------------

function chartDatasetsEnd {
  echo "            }"
  echo "          ]"
}

# --------------------------------------------------------------------------------------------------

function chartDataset {
  local label="${1}"
  local data="${2}"
  local color="${3}"
  local first="${4}"

  if [[ "${first}" != "true" ]]; then
    echo "            },"
  fi
  echo "            {"
  echo "              label: '${label}',"
  echo "              data: [${data}],"
  echo "              backgroundColor: ["
  echo "                'rgba(${color}, 0.2)'"
  echo "              ],"
  echo "              borderColor: ["
  echo "                'rgba(${color}, 1)'"
  echo "              ],"
  echo "              borderWidth: 1,"
  echo "              fill: false"
}

# --------------------------------------------------------------------------------------------------

function getDatasetForX {
  local fieldName="${1}"
  local reportFolder="${2}"
  local reportFileName="${3}"

  local format="${4}||||||||||"
  local paramList1=()
  local paramList2=()
  local paramList3=()
  local paramList4=()
  local paramList5=()
  local paramList6=()

  read -r -a paramList1 <<< "${5:--}"
  read -r -a paramList2 <<< "${6:--}"
  read -r -a paramList3 <<< "${7:--}"
  read -r -a paramList4 <<< "${8:--}"
  read -r -a paramList5 <<< "${9:--}"
  read -r -a paramList6 <<< "${10:--}"

  local result=""

  for param1 in "${paramList1[@]}"; do
    for param2 in "${paramList2[@]}"; do
      for param3 in "${paramList3[@]}"; do
        for param4 in "${paramList4[@]}"; do
          for param5 in "${paramList5[@]}"; do
            for param6 in "${paramList6[@]}"; do

#              echo "${param1} ${param2} ${param3} ${param4} ${param5} ${param6}"

              local folderName=""
              printf -v folderName -- "${format}" "${param1}" "${param2}" "${param3}" "${param4}" "${param5}" "${param6}"
              folderName="${folderName%%\|\|\|\|\|\|\|\|\|\|*}"
#              printf "${folderName}\n\n"

              if [[ -f "${reportFolder}/${folderName}/${reportFileName}" ]]; then

#                echo "FOUND"

                local sum=0
                local cnt=0

                local fieldNameIndex=0
                local firstLine="true"
                local line
                while IFS='' read -r line || [[ -n "$line" ]]; do
                  local fields=()
                  IFS=',' read -ra fields <<< "${line}"
                  if [[ "${firstLine}" == "true" ]]; then
                    firstLine="false"
                    local fieldIndex
                    for fieldIndex in "${!fields[@]}"; do
                        if [[ "${fields[fieldIndex]}" == "${fieldName}" ]]; then
                          fieldNameIndex=${fieldIndex}
  #                        echo "Field name index: ${fieldNameIndex}"
                        fi
                    done
                  else
                    sum=$(floatSum ${sum} ${fields[fieldNameIndex]})
                    ((cnt++))
                  fi
                done < "${reportFolder}/${folderName}/${reportFileName}"

                result="${result},$(floatDiv ${sum} ${cnt})"
              fi
            done
          done
        done
      done
    done
  done

  echo "${result:1}"
}

# --------------------------------------------------------------------------------------------------

config='
{
  "scenarioFolderPattern": "${testName}-srt-${srt}-tmt-${tmt}-uc-${uc}-rps-${rps}",
  "scenarioFileNamePattern": "report.csv",
  "fields": [
    {
      "name": "testName",
      "values": ["AsyncRestThrottled"]
    },
    {
      "name": "srt",
      "values": [10, 50, 200]
    },
    {
      "name": "tmt",
      "values": [10, 20, 50]
    },
    {
      "name": "rps",
      "values": [5000, 6000, 7000, 8000, 9000, 10000]
    },
    {
      "name": "uc",
      "values": [2500, 2000],
      "type": "singleMatch"
    }
  ],
  "repeatCount": 3,
  "report": {
    "header": {
      "fieldNames": [ "testName", "srt" ],
      "label": "${testName} @ ${srt}ms"
    },
    "dataset": {
      "fieldNames": [ "tmt" ],
      "label": "${tmt} threads"
    },
    "axis": {
      "fieldName": "rps",
      "label": "${rps} rps"
    },
    "rows": [
      {
        "name": "Req/s",
        "scriptName": "mean_rps",
        "text": "Mean RPS @ no. of threads"
      },
      {
        "name": "Mean",
        "scriptName": "mean_response_time",
        "text": "Mean response time @ no. of threads"
      },
      {
        "name": "Failed",
        "scriptName": "error",
        "text": "Errors @ no. of threads"
      },
      {
        "name": "95th",
        "scriptName": "95th_percentile",
        "text": "95th percentile @ no. of threads"
      },
      {
        "name": "99th",
        "scriptName": "99th_percentile",
        "text": "99th percentile @ no. of threads"
      },
      {
        "name": "Max",
        "scriptName": "max_percentile",
        "text": "Max percentile @ no. of threads"
      },
      {
        "name": "Peak",
        "scriptName": "peak_threads",
        "text": "Peak threads @ no. of threads"
      }
    ]
  }
}
'

function loopFields {
  local __loopFields_fields="${1}"
  shift

#  echo "FIELDS: ${__loopFields_fields}"

  if [[ "${#}" == "1" ]]; then

#    echo "EXECUTING LAMBDA: ${1}"

    eval "${1}"
  else
    local __loopFields_fieldName="${1}"
    shift
    local __loopFields_fieldNamesWithLambda=("${@}")

#    echo "FIELD NAME: ${__loopFields_fieldName}"
#
#    echo "FIELDS WITH LAMBDA: ${__loopFields_fieldNamesWithLambda[@]}"

    local __loopFields_field

#    echo "THE JSON EXPRESSION: __loopFields_field = __loopFields_fields.[] | select(.name=\"${__loopFields_fieldName}\")"

    json "__loopFields_field = __loopFields_fields.[] | select(.name==\"${__loopFields_fieldName}\")"

#    echo "THE FIELD: ${__loopFields_field}"

    local __loopFields_fieldType
    json __loopFields_fieldType = __loopFields_field.type

#    echo "THE FIELD TYPE: ${__loopFields_fieldType}"

    local __loopFields_fieldValues=()
    json __loopFields_fieldValues = __loopFields_field.values[]

#    echo "THE FIELD VALUES: ${__loopFields_fieldValues[@]}"

    local __loopFields_fieldValue
    for __loopFields_fieldValue in "${__loopFields_fieldValues[@]}"; do
      eval "local ${__loopFields_fieldName}=\"${__loopFields_fieldValue}\""

      loopFields "${__loopFields_fields}" "${__loopFields_fieldNamesWithLambda[@]}"
    done
  fi
}


function generateReport {
  echo "<html lang=\"en\">
  <head>
    <title>Report for ${testName}</title>
    <script src=\"https://cdnjs.cloudflare.com/ajax/libs/Chart.js/2.4.0/Chart.min.js\"></script>
    <style>
      html, body {
        height: 100%;
      }
      body {
        margin: 0;
        display: flex;
      }
      .divTable{
        display: table;
        width: 930px;
      }
      .divTableRow {
        display: table-row;
      }
      .divTableHeading {
        display: table-header-group;
      }
      .divTableHeading, .divTableFirst {
        background-color: #EEE;
        font-weight: bold;
      }
      .divTableCell, .divTableHead, .divTableFirst {
        border: 1px solid #999999;
        display: table-cell;
        padding: 3px 10px;
        width: 300px;
      }
      .divTableHead, .divTableFirst {
        text-align: center;
        vertical-align: middle;
      }
      /*.divTableFoot {*/
        /*background-color: #EEE;*/
        /*display: table-footer-group;*/
        /*font-weight: bold;*/
      /*}*/
      .divTableBody {
        display: table-row-group;
      }
    </style>
  </head>
  <body>"

  # ------------------------------------------------------------------------------------------------

  local fieldsConfig
  json fieldsConfig = config.fields

  local scenarioFolderPattern
  json scenarioFolderPattern = config.scenarioFolderPattern

  local scenarioFileNamePattern
  json scenarioFileNamePattern = config.scenarioFileNamePattern

  # ------------------------------------------------------------------------------------------------

  local report
  json report = config.report

  # ------------------------------------------------------------------------------------------------

  local header
  json header = report.header

  local headerFieldNames=()
  json headerFieldNames = header.fieldNames[]

  # ------------------------------------------------------------------------------------------------

  local dataset
  json dataset = report.dataset

  local datasetFieldNames=()
  json datasetFieldNames = dataset.fieldNames[]

  # ------------------------------------------------------------------------------------------------

  local axis
  json axis = report.axis

  local axisFieldName
  json axisFieldName = axis.fieldName

  local axisValues=()
  json "axisValues = config.fields[] | select(.name==\"${axisFieldName}\") | .values[]"

  # ------------------------------------------------------------------------------------------------

  local singleMatchFieldNames=()
  json "singleMatchFieldNames = config.fields[] | select(.type==\"singleMatch\") | .name"

  # ------------------------------------------------------------------------------------------------

  local rows=()
  json rows = report.rows[]

  # ------------------------------------------------------------------------------------------------
  # create the table
  # ------------------------------------------------------------------------------------------------

  tableStart

    # ----------------------------------------------------------------------------------------------
    # table header row
    # ----------------------------------------------------------------------------------------------

    tableHeadingStart
      tableRowStart

        tableColumnHead "&nbsp;"

        local headerLabelPattern
        json headerLabelPattern = header.label

        loopFields "${fieldsConfig}" "${headerFieldNames[@]}" '
          eval "local headerLabel=\"${headerLabelPattern}\""
          tableColumnHead "${headerLabel}"
        '

      tableRowEnd
    tableHeadingEnd

    # ----------------------------------------------------------------------------------------------
    # table data rows with the canvas declarations
    # ----------------------------------------------------------------------------------------------

    tableBodyStart

      local row
      for row in "${rows[@]}"; do
        local scriptName
        json scriptName = row.scriptName

        local text
        json text = row.text

        tableRowStart

          firstColumn "${text}"

          local chartNamePattern="${scriptName}"
          local headerFieldName
          for headerFieldName in "${headerFieldNames[@]}"; do
            chartNamePattern="${headerFieldName}_\${${headerFieldName}}_${chartNamePattern}"
          done

          loopFields "${fieldsConfig}" "${headerFieldNames[@]}" '
            eval "local chartName=\"${chartNamePattern}\""
            declareCanvas "${chartName}"
          '

        tableRowEnd
      done

    tableBodyEnd

  tableEnd

  # ------------------------------------------------------------------------------------------------
  # create the chart contents
  # ------------------------------------------------------------------------------------------------

  chartScriptStart

    local row
    for row in "${rows[@]}"; do

      local reportColName
      json reportColName = row.name

      local scriptName
      json scriptName = row.scriptName

      local chartNamePattern="${scriptName}"
      local headerFieldName
      for headerFieldName in "${headerFieldNames[@]}"; do
        chartNamePattern="${headerFieldName}_\${${headerFieldName}}_${chartNamePattern}"
      done

      loopFields "${fieldsConfig}" "${headerFieldNames[@]}" '
        eval "local chartName=\"${chartNamePattern}\""
        chartStart "${chartName}"
          local axisLabels=$(joinValues , ${axisValues[@]})
          chartLabels ${axisLabels}
          chartDatasetsStart
            local colorIndex=0
            local first="true"

            loopFields "${fieldsConfig}" "${datasetFieldNames[@]}" '"'"'
              local dsResult
              local axisValue
              for axisValue in "${axisValues[@]}"; do
                eval "${axisFieldName}=\"${axisValue}\""
#                echo "${axisValue}"
                loopFields "${fieldsConfig}" "${singleMatchFieldNames[@]}" '"'\"'\"'"'
                  eval "local folderName=\"${scenarioFolderPattern}\""
                  eval "local fileName=\"${scenarioFileNamePattern}\""
#                  echo "${reportFolder}/${folderName}/${fileName}"

                  if [[ -f "${reportFolder}/${folderName}/${fileName}" ]]; then

#                    echo "FOUND"

                    local sum=0
                    local cnt=0

                    local fieldNameIndex=0
                    local firstLine="true"
                    local line
                    while IFS='' read -r line || [[ -n "$line" ]]; do
                      local fields=()
                      IFS=',' read -ra fields <<< "${line}"
                      if [[ "${firstLine}" == "true" ]]; then
                        firstLine="false"
                        local fieldIndex
                        for fieldIndex in "${!fields[@]}"; do
                            if [[ "${fields[fieldIndex]}" == "${reportColName}" ]]; then
                              fieldNameIndex=${fieldIndex}
      #                        echo "Field name index: ${fieldNameIndex}"
                            fi
                        done
                      else
                        sum=$(floatSum ${sum} ${fields[fieldNameIndex]})
                        ((cnt++))
                      fi
                    done < "${reportFolder}/${folderName}/${fileName}"

#                    echo "$(floatDiv ${sum} ${cnt})"

                    dsResult="${dsResult},$(floatDiv ${sum} ${cnt})"
                  fi

                '"'\"'\"'"'
              done

              local datasetLabelPattern
              json datasetLabelPattern = dataset.label

              eval "datasetLabel=\"${datasetLabelPattern}\""

              chartDataset "${datasetLabel}" "${dsResult:1}" "${colors[colorIndex]}" "${first}"

              ((colorIndex++))
              first="false"
            '"'"'
          chartDatasetsEnd
        chartEnd
      '

    done




#              data="$(getDatasetFor "${reportColName}" "${reportFolder}" "${reportFileName}" "${reportFolderFormat}" "${headerValue}" "${tmt}" "${ucList[*]}" "${rpsList[*]}")"
#              chartDataset "${tmt}" "${data}" "${colors[colorIndex]}" "${first}"





#    for field in "${fieldList[@]}"; do
#
#      fieldName="$(fieldName "${field}")"
#      fieldScriptName="$(fieldScriptName "${field}")"
#
#      for srt in "${srtList[@]}"; do
#        chartStart "srt_${srt}_${fieldScriptName}"
#          labels=$(joinValues , ${rpsList[@]})
#          chartLabels ${labels}
#          chartDatasetsStart
#            colorIndex=0
#            first="true"
#            for tmt in "${tmtList[@]}"; do
#              data="$(getDatasetFor "${fieldName}" "${reportFolder}" "${reportFileName}" "${reportFolderFormat}" "${srt}" "${tmt}" "${ucList[*]}" "${rpsList[*]}")"
#              chartDataset "${tmt}" "${data}" "${colors[colorIndex]}" "${first}"
#              ((colorIndex++))
#              first="false"
#            done
#          chartDatasetsEnd
#        chartEnd
#      done
#
#    done

  chartScriptEnd

  ##################################################################

  echo "  </body>"
  echo "</html>"
}

# ==================================================================================================
# ==================================================================================================
# ==================================================================================================
# ==================================================================================================
# ==================================================================================================

pushd "${projDir}" > /dev/null

mkdir -p "${reportFolder}"
echo "" > "${reportFolder}/${htmlReportName}"

generateReport >> "${reportFolder}/${htmlReportName}"

popd > /dev/null