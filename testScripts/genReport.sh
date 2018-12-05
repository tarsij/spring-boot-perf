#!/usr/bin/env bash

scriptDir="$(cd "$(dirname "$0")" ; pwd -P )"
projDir="$scriptDir/.."

# Defaults

reportFolder="reports/test"
reportFileName="report.csv"

simulationName="AsyncRestThrottled"
htmlReportName="report.html"
reportFolderFormat="${simulationName}-srt-%s-tmt-%s-uc-%s-rps-%s"

declare -a colors=('255, 99, 132' '54, 162, 235' '255, 206, 86' '75, 192, 192' '153, 102, 255' '255, 159, 64')

declare -a srtList=(10 50 200)
declare -a tmtList=(10 20 50)
declare -a ucList=(2000 2500)
declare -a rpsList=(5000 6000 7000 8000 9000 10000)

declare -a fieldList=("Req/s|mean_rps|Mean RPS @ no. of threads"
                      "Mean|mean_response_time|Mean response time @ no. of threads"
                      "Failed|error|Errors @ no. of threads"
                      "95th|95th_percentile|95th percentile @ no. of threads"
                      "99th|99th_percentile|99th percentile @ no. of threads"
                      "Max|max_percentile|Max percentile @ no. of threads"
                      "Peak|peak_threads|Peak threads @ no. of threads"
                      )

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

  if [ ${value} -lt 0 ]; then
    negative="-"
    ((value=-value))
  fi

  local valueD=${value}
  local valueP=${value}

  ((valueD/=1000))
  ((valueP-=valueD*1000))

  if [ "${valueP}" == "0" ]; then
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

  if [ "${first}" != "true" ]; then
    echo "            },"
  fi
  echo "            {"
  echo "              label: '${tmt}',"
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

function getDatasetFor {
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

              if [ -f "${reportFolder}/${folderName}/${reportFileName}" ]; then

#                echo "FOUND"

                local sum=0
                local cnt=0

                local fieldNameIndex=0
                local firstLine="true"
                local line
                while IFS='' read -r line || [[ -n "$line" ]]; do
                  local fields
                  IFS=',' read -ra fields <<< "${line}"
                  if [ "${firstLine}" == "true" ]; then
                    firstLine="false"
                    local fieldIndex
                    for fieldIndex in "${!fields[@]}"; do
                        if [ "${fields[fieldIndex]}" == "${fieldName}" ]; then
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

# ##################################################################################################

mkdir -p "${reportFolder}"
echo "" > "${reportFolder}/${htmlReportName}"

echo "<html lang=\"en\">
  <head>
    <title>Report for ${simulationName}</title>
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
  <body>" >> "${reportFolder}/${htmlReportName}"

      echo "$(tableStart)" >> "${reportFolder}/${htmlReportName}"

        ##################################################################

        echo "$(tableHeadingStart)" >> "${reportFolder}/${htmlReportName}"
          echo "$(tableRowStart)" >> "${reportFolder}/${htmlReportName}"
            echo "$(tableColumnHead "&nbsp;")" >> "${reportFolder}/${htmlReportName}"
            for srt in "${srtList[@]}"; do
              echo "$(tableColumnHead "@ ${srt}ms")" >> "${reportFolder}/${htmlReportName}"
            done
          echo "$(tableRowEnd)" >> "${reportFolder}/${htmlReportName}"
        echo "$(tableHeadingEnd)" >> "${reportFolder}/${htmlReportName}"

        ##################################################################

        echo "$(tableBodyStart)" >> "${reportFolder}/${htmlReportName}"

          for field in "${fieldList[@]}"; do

            fieldScriptName="$(fieldScriptName "${field}")"
            fieldReportName="$(fieldReportName "${field}")"

            echo "$(tableRowStart)" >> "${reportFolder}/${htmlReportName}"
              echo "$(firstColumn "${fieldReportName}")" >> "${reportFolder}/${htmlReportName}"
              for srt in "${srtList[@]}"; do
                 echo "$(declareCanvas "srt_${srt}_${fieldScriptName}")" >> "${reportFolder}/${htmlReportName}"
              done
            echo "$(tableRowEnd)" >> "${reportFolder}/${htmlReportName}"

           done

        echo "$(tableBodyEnd)" >> "${reportFolder}/${htmlReportName}"

        ##################################################################

      echo "$(tableEnd)" >> "${reportFolder}/${htmlReportName}"

      ##############################################################################################
      ##############################################################################################
      ##############################################################################################

      echo "$(chartScriptStart)" >> "${reportFolder}/${htmlReportName}"

        for field in "${fieldList[@]}"; do

          fieldName="$(fieldName "${field}")"
          fieldScriptName="$(fieldScriptName "${field}")"

          for srt in "${srtList[@]}"; do
            echo "$(chartStart "srt_${srt}_${fieldScriptName}")" >> "${reportFolder}/${htmlReportName}"
              labels=$(joinValues , ${rpsList[@]})
              echo "$(chartLabels ${labels})" >> "${reportFolder}/${htmlReportName}"
              echo "$(chartDatasetsStart)" >> "${reportFolder}/${htmlReportName}"
                colorIndex=0
                first="true"
                for tmt in "${tmtList[@]}"; do
                  data="$(getDatasetFor "${fieldName}" "${reportFolder}" "${reportFileName}" "${reportFolderFormat}" "${srt}" "${tmt}" "${ucList[*]}" "${rpsList[*]}")"
                  echo "$(chartDataset "${tmt}" "${data}" "${colors[colorIndex]}" "${first}")" >> "${reportFolder}/${htmlReportName}"
                  ((colorIndex++))
                  first="false"
                done
              echo "$(chartDatasetsEnd)" >> "${reportFolder}/${htmlReportName}"
            echo "$(chartEnd)" >> "${reportFolder}/${htmlReportName}"
          done

        done

      echo "$(chartScriptEnd)" >> "${reportFolder}/${htmlReportName}"

      ##################################################################

      echo "  </body>" >> "${reportFolder}/${htmlReportName}"
      echo "</html>" >> "${reportFolder}/${htmlReportName}"
