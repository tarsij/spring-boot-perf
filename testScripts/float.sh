#!/usr/bin/env bash

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

# --------------------------------------------------------------------------------------------------
