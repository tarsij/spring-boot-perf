#!/usr/bin/env bash

scriptDir="$(cd "$(dirname "$0")" ; pwd -P )"
projDir="$scriptDir/.."

source ${scriptDir}/json.sh
source ${scriptDir}/float.sh

# ##################################################################################################

function joinValues {
  local IFS="$1"

  shift
  echo "$*"
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

# ==================================================================================================
#  prepareLoopFields
#  ------------------------------
#  - usage: prepareLoopFields "<fieldsConfig>" "<field1>" ... "<fieldN>"
#
#  - it is just a performance improvement: because json is a costly operation the field values are
#    prefetched and stored in an array
#  - NOTE: it creates some global variables for the loopField so it can access them
# --------------------------------------------------------------------------------------------------
function prepareLoopFields {
  local __loopFields_fieldsConfig="${1}"
  shift
  local __loopFields_fieldNames=("${@}")

  local __loopFields_fieldName
  for __loopFields_fieldName in "${__loopFields_fieldNames[@]}"; do
      local __loopFields_fieldConfig
      json "__loopFields_fieldConfig = __loopFields_fieldsConfig.[] | select(.name==\"${__loopFields_fieldName}\")"

      # --------------------------------------------------------------------------------------------
      # !!! NOTE: these variables are global so the loopFields can access them
      # --------------------------------------------------------------------------------------------
      eval "json __loopFields_${__loopFields_fieldName}_fieldValues = __loopFields_fieldConfig.values[]"
  done
}

# ==================================================================================================
#  loopFields
#  ------------------------------
#  - usage: loopFields "<fieldsConfig>" "<field1>" ... "<fieldN>" "<lambda>"
#
#  - loops over the fields specified
#  - it uses the global arrays defined by the prepareLoopFields
# --------------------------------------------------------------------------------------------------
function loopFields {
  local __loopFields_fieldsConfig="${1}"
  shift

  if [[ "${#}" == "1" ]]; then
    eval "${1}"
  else
    local __loopFields_fieldName="${1}"
    shift
    local __loopFields_fieldNamesWithLambda=("${@}")

    local __loopFields_fieldValues=()
    eval "__loopFields_fieldValues=(\"\${__loopFields_${__loopFields_fieldName}_fieldValues[@]}\")"

    local __loopFields_fieldValue
    for __loopFields_fieldValue in "${__loopFields_fieldValues[@]}"; do
      eval "local ${__loopFields_fieldName}=\"${__loopFields_fieldValue}\""

      loopFields "${__loopFields_fieldsConfig}" "${__loopFields_fieldNamesWithLambda[@]}"
    done
  fi
}

# ==================================================================================================
#  loopFields2
#  ------------------------------
#  - usage: loopFields2 "<fieldsConfig>" "<field1>" ... "<fieldN>" "<lambda>"
#
#  - loops over the fields specified
#  - it parses the json configuration for the field values
#  - because the json operation is costly its performance is much worse than of the loopFields
#    which uses predeclared arrays
# --------------------------------------------------------------------------------------------------
function loopFields2 {
  local __loopFields_fieldsConfig="${1}"
  shift

  if [[ "${#}" == "1" ]]; then
    eval "${1}"
  else
    local __loopFields_fieldName="${1}"
    shift
    local __loopFields_fieldNamesWithLambda=("${@}")

    local __loopFields_field
    json "__loopFields_field = __loopFields_fieldsConfig.[] | select(.name==\"${__loopFields_fieldName}\")"

    local __loopFields_fieldValues=()
    json __loopFields_fieldValues = __loopFields_field.values[]

    local __loopFields_fieldValue
    for __loopFields_fieldValue in "${__loopFields_fieldValues[@]}"; do
      eval "local ${__loopFields_fieldName}=\"${__loopFields_fieldValue}\""

      loopFields2 "${__loopFields_fieldsConfig}" "${__loopFields_fieldNamesWithLambda[@]}"
    done
  fi
}

# ==================================================================================================
#  generateReport
#  ------------------------------
#  - usage: generateReport
#
#  - generates the html report
# --------------------------------------------------------------------------------------------------
function generateReport {

  local fieldsConfig
  json fieldsConfig = config.fields

  local testName
  json testName = config.testName

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

  prepareLoopFields "${fieldsConfig}" "${headerFieldNames[@]}" "${datasetFieldNames[@]}" "${axisFieldName}" "${singleMatchFieldNames[@]}"

  # ------------------------------------------------------------------------------------------------
  # create the report header
  # ------------------------------------------------------------------------------------------------

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
            chartNamePattern="${chartNamePattern}_${headerFieldName}_\${${headerFieldName}}"
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
        chartNamePattern="${chartNamePattern}_${headerFieldName}_\${${headerFieldName}}"
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
                loopFields "${fieldsConfig}" "${singleMatchFieldNames[@]}" '"'\"'\"'"'
                  eval "local folderName=\"${scenarioFolderPattern}\""
                  eval "local fileName=\"${scenarioFileNamePattern}\""

                  if [[ -f "${reportFolder}/${folderName}/${fileName}" ]]; then
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
                            fi
                        done
                      else
                        sum=$(floatSum ${sum} ${fields[fieldNameIndex]})
                        ((cnt++))
                      fi
                    done < "${reportFolder}/${folderName}/${fileName}"

                    dsResult="${dsResult},$(floatDiv ${sum} ${cnt})"

                    break "${#singleMatchFieldNames[@]}"
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

  chartScriptEnd

  # ------------------------------------------------------------------------------------------------

  echo "  </body>"
  echo "</html>"
}

# ==================================================================================================
# ==================================================================================================
# ==================================================================================================
# ==================================================================================================
# ==================================================================================================

function main {
  local reportFolder="${1}"
  local configFileName="${2:-config.json}"
  local htmlReportName="${3:-report.html}"

  local colors=(
    '244, 67, 54'
    '63, 81, 181'
    '0, 150, 136'
    '255, 206, 86'
    '156, 39, 176'
    '3, 169, 244'
    '139, 195, 74'
    '255, 152, 0'
    '233, 30, 99'
    '33, 150, 243'
    '76, 175, 80'
    '255, 193, 7'
    '103, 58, 183'
    '0, 188, 212'
    '205, 220, 57'
    '255, 99, 132'
    '54, 162, 235'
    '153, 102, 255'
    '255, 87, 34'
    '96, 125, 139'
    '255, 159, 64'
    '121, 85, 72'
  )

  echo "START: $(date)" > /dev/tty

  pushd "${projDir}" > /dev/null

  pwd > /dev/tty

  local config="$(cat ${reportFolder}/${configFileName})"

  generateReport > "${reportFolder}/${htmlReportName}"

  popd > /dev/null

  echo "END: $(date)" > /dev/tty
}

# ==================================================================================================

main "${@}"