#!/usr/bin/env bash

scriptDir="$(cd "$(dirname "$0")" ; pwd -P )"
projDir="$scriptDir/.."

pushd "${projDir}" > /dev/null

timestamp=$(date +%s)

mvn clean install

# Service response time: 10 50 200
#for srt in "10" "50" "200"; do
for srt in "150"; do
  # Tomcat max threads: 10 20 50
#  for tmt in "80" "400"; do
  for tmt in "120" "600" "1600" "2400" "6000"; do
#  for tmt in "9000"; do
    # user count: 2500
    for uc in "2500"; do
      # Requests per second: 5000 6000 7000
#      for rps in "5000" "7000" "9000"; do
      for rps in "5000" "6000" "7000" "8000" "9000" "10000"; do
        # Repeat count: 3
        for rc in "0" "1" "2"; do
          ${scriptDir}/runScenario.sh --report-folder "reports/test-${timestamp}/SyncRestThrottled-srt-${srt}-tmt-${tmt}-uc-${uc}-rps-${rps}" \
                                      --report-filename "report.csv" \
                                      --service-url "http://localhost:8888" \
                                      --simulation-class "simulations.SyncRestThrottled" \
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