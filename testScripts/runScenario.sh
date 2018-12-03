#!/usr/bin/env bash

scriptDir="$(cd "$(dirname "$0")" ; pwd -P )"
projDir="$scriptDir/.."

# Defaults

serviceResponseTime=10
tomcatMaxThreads=20

reportFolder="reports"
reportFileName="results.csv"
simulationClass="simulations.AsyncRestThrottled"
serviceUrl="http://localhost:8888"
reqPerSec="5000"
userCount="100"
rampUpDuration="10 seconds"
testDuration="10 seconds"

# Parse the parameters

while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    --srt|--service-response-time)
      serviceResponseTime="$2"
      shift
      shift
    ;;
    --tmt|--tomcat-max-threads)
      tomcatMaxThreads="$2"
      shift
      shift
    ;;
    --rf|--report-folder)
      reportFolder="$2"
      shift
      shift
    ;;
    --rfn|--report-filename)
      reportFileName="$2"
      shift
      shift
    ;;
    --sc|--simulation-class)
      simulationClass="$2"
      shift
      shift
    ;;
    --su|--service-url)
      serviceUrl="$2"
      shift
      shift
    ;;
    --rps|--requests-per-second)
      reqPerSec="$2"
      shift
      shift
    ;;
    --uc|--user-count)
      userCount="$2"
      shift
      shift
    ;;
    --rud|--ramp-up-duration)
      rampUpDuration="$2"
      shift
      shift
    ;;
    --td|--test-duration)
      testDuration="$2"
      shift
      shift
    ;;
    -h|--help)
      shift
      echo "Usage comes here soon"
      exit
    ;;
    *)
      echo "Unknown parameter ${key}. Use -h or --help to get a usage description"
      shift
      exit 1
    ;;
  esac
done

reportFile="${reportFolder}/${reportFileName}"
gatlingFolder="${reportFolder}/gatling"

pushd "${projDir}" > /dev/null

echo
echo "================================================================================"
echo "Check if service is up..."

serviceStatus=$(curl -s http://localhost:8888/manage/health | jq -r '.status')
if [ "${serviceStatus}" == "UP" ]; then
  echo "  - service is already running. Check the '${reportFolder}/error.log' for more details. Exit..."

  timestamp=$(date)
  echo "--- ${timestamp} --------------------------------------------------" >> "${reportFolder}/error.log"
  echo "  The service is already up so the test couldn't start with the desired settings:" >> "${reportFolder}/error.log"
  echo "    - service response time: ${serviceResponseTime}" >> "${reportFolder}/error.log"
  echo "    - tomcat max threads: ${tomcatMaxThreads}" >> "${reportFolder}/error.log"
  echo "    - simulation class: ${simulationClass}" >> "${reportFolder}/error.log"
  echo "    - service url: ${serviceUrl}" >> "${reportFolder}/error.log"
  echo "    - requests per second: ${reqPerSec}" >> "${reportFolder}/error.log"
  echo "    - user count: ${userCount}" >> "${reportFolder}/error.log"
  echo "    - ramp-up duration: ${rampUpDuration}" >> "${reportFolder}/error.log"
  echo "    - test duration: ${testDuration}" >> "${reportFolder}/error.log"
  echo >> "${reportFolder}/error.log"

  exit 1
else
  echo "  - service is not running"
fi


echo
echo "================================================================================"
echo "Start the service..."

mvn spring-boot:run -pl spring-boot-app \
                    -Dservice.response.duration="${serviceResponseTime}" \
                    -Dserver.tomcat.maxThreads="${tomcatMaxThreads}" > spring-boot-app/target/service.log 2>&1 &
servicePid=${!}

echo "  - service PID: ${servicePid}"
echo "  - service response time: ${serviceResponseTime}"
echo "  - tomcat max threads: ${tomcatMaxThreads}"


echo
echo "================================================================================"
echo -n "Wait until service is up..."

while : ; do
  serviceStatus=$(curl -s http://localhost:8888/manage/health | jq -r '.status')
  echo -n "."
  if [ "${serviceStatus}" != "UP" ]; then
    sleep 1
  else
    break
  fi
done

echo
echo "  - service is up"

echo
echo "================================================================================"
echo "Start the test..."

mvn scala:run -pl gatling-tests \
              -Dgatling.simulationClass="${simulationClass}" \
              -Dgatling.resultsFolder="../${gatlingFolder}" \
              -Dtest.serviceUrl="${serviceUrl}" \
              -Dtest.reqPerSec="${reqPerSec}" \
              -Dtest.userCount="${userCount}" \
              -Dtest.rampUpDuration="${rampUpDuration}" \
              -Dtest.testDuration="${testDuration}" | tee gatling-tests/target/gatling.log

echo
echo "================================================================================"
echo "Get some metrics:"
echo

value=$(curl -s http://localhost:8888/manage/metrics | jq '."threads"')
echo "threads: ${value}"
threads="${value}"

value=$(curl -s http://localhost:8888/manage/metrics | jq '."threads.daemon"')
echo "threads.daemon: ${value}"
threadsDaemon="${value}"

value=$(curl -s http://localhost:8888/manage/metrics | jq '."threads.peak"')
echo "threads.peak: ${value}"
threadsPeak="${value}"

echo
echo "================================================================================"
echo "Interpret the results:"
echo

mkdir -p reports

if [ ! -f "${reportFile}" ]; then
  echo "Simulation,Tomcat,Threads,Daemon,Peak,RampUp,Duration,User,Ideal Req/s,Max Count,Max Req/s,Count,Req/s,Min,50th,75th,95th,99th,Max,Mean,Deviation,Quick,Medium,Slow,Failed,Test Folder" >> "${reportFile}"
fi

echo -n "${simulationClass}" >> "${reportFile}"

echo -n ",${tomcatMaxThreads}" >> "${reportFile}"
echo -n ",${threads}" >> "${reportFile}"
echo -n ",${threadsDaemon}" >> "${reportFile}"
echo -n ",${threadsPeak}" >> "${reportFile}"

echo -n ",${rampUpDuration}" >> "${reportFile}"
echo -n ",${testDuration}" >> "${reportFile}"
echo -n ",${userCount}" >> "${reportFile}"
echo -n ",${reqPerSec}" >> "${reportFile}"

value=$(cat gatling-tests/target/gatling.log | grep " completed in " | sed -E 's/.* ([0-9]+) .*/\1/g')
echo "test completed in: ${value}"
completedIn="${value}"

value=$(cat gatling-tests/target/gatling.log | grep "Ideal request count:" | sed -E 's/.* ([0-9]+) .*/\1/g')
echo "max request count: ${value}"
echo -n ",${value}" >> "${reportFile}"

value=$((value / completedIn))
echo "max requests/s: ${value}"
echo -n ",${value}" >> "${reportFile}"

value=$(cat gatling-tests/target/gatling.log | grep "> request count" | sed -E 's/.* ([0-9]+) .*/\1/g')
echo "request count: ${value}"
echo -n ",${value}" >> "${reportFile}"

value=$(cat gatling-tests/target/gatling.log | grep "> mean requests\/sec" | sed -E 's/.* ([0-9.]+) .*/\1/g')
echo "mean requests/sec: ${value}"
echo -n ",${value}" >> "${reportFile}"

value=$(cat gatling-tests/target/gatling.log | grep "> min response time" | sed -E 's/.* ([0-9]+) .*/\1/g')
echo "min response time: ${value}"
echo -n ",${value}" >> "${reportFile}"

value=$(cat gatling-tests/target/gatling.log | grep "> response time 50th percentile" | sed -E 's/.* ([0-9]+) .*/\1/g')
echo "response time 50th percentile: ${value}"
echo -n ",${value}" >> "${reportFile}"

value=$(cat gatling-tests/target/gatling.log | grep "> response time 75th percentile" | sed -E 's/.* ([0-9]+) .*/\1/g')
echo "response time 75th percentile: ${value}"
echo -n ",${value}" >> "${reportFile}"

value=$(cat gatling-tests/target/gatling.log | grep "> response time 95th percentile" | sed -E 's/.* ([0-9]+) .*/\1/g')
echo "response time 95th percentile: ${value}"
echo -n ",${value}" >> "${reportFile}"

value=$(cat gatling-tests/target/gatling.log | grep "> response time 99th percentile" | sed -E 's/.* ([0-9]+) .*/\1/g')
echo "response time 99th percentile: ${value}"
echo -n ",${value}" >> "${reportFile}"

value=$(cat gatling-tests/target/gatling.log | grep "> max response time" | sed -E 's/.* ([0-9]+) .*/\1/g')
echo "max response time: ${value}"
echo -n ",${value}" >> "${reportFile}"

value=$(cat gatling-tests/target/gatling.log | grep "> mean response time" | sed -E 's/.* ([0-9]+) .*/\1/g')
echo "mean response time: ${value}"
echo -n ",${value}" >> "${reportFile}"

value=$(cat gatling-tests/target/gatling.log | grep "> std deviation" | sed -E 's/.* ([0-9]+) .*/\1/g')
echo "std deviation: ${value}"
echo -n ",${value}" >> "${reportFile}"

value=$(cat gatling-tests/target/gatling.log | grep "> t < 800 ms" | sed -E 's/.* ([0-9]+) .*/\1/g')
echo "t < 800 ms: ${value}"
echo -n ",${value}" >> "${reportFile}"

value=$(cat gatling-tests/target/gatling.log | grep "> 800 ms < t < 1200 ms" | sed -E 's/.* ([0-9]+) .*/\1/g')
echo "800 ms < t < 1200 ms: ${value}"
echo -n ",${value}" >> "${reportFile}"

value=$(cat gatling-tests/target/gatling.log | grep "> t > 1200 ms" | sed -E 's/.* ([0-9]+) .*/\1/g')
echo "t > 1200 ms: ${value}"
echo -n ",${value}" >> "${reportFile}"

value=$(cat gatling-tests/target/gatling.log | grep "> failed" | sed -E 's/.* ([0-9]+) .*/\1/g')
echo "failed: ${value}"
echo -n ",${value}" >> "${reportFile}"

value=$(cat gatling-tests/target/gatling.log | grep "Please open the following file:" | sed -E "s/.*\/([a-zA-Z0-9-]+)\/index\.html.*/\1/g")
echo "report name: ${value}"
echo -n ",${value}" >> "${reportFile}"

echo >> "${reportFile}"

echo
echo "================================================================================"
echo "Stop the service..."

kill ${servicePid}

echo "  - service stopped"

echo

popd > /dev/null