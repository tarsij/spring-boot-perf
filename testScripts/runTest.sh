#!/usr/bin/env bash

scriptDir="$(cd "$(dirname "$0")" ; pwd -P )"
projDir="$scriptDir/.."

pushd "${projDir}" > /dev/null

timestamp=$(date +%s)

mvn clean install

# Service response time: 10 50 200
for srt in "10" "50" "200"; do
  # Tomcat max threads: 10 20 50
  for tmt in "10" "20" "50"; do
    # user count: 2000
    for uc in "2000"; do
      # Requests per second: 5000 6000 7000
#      for rps in "5000" "6000" "7000"; do
      for rps in "7500" "8000" "8500"; do
        # Repeat count: 3
        for rc in "0" "1" "2"; do
          ${scriptDir}/runScenario.sh --report-folder "reports/test-${timestamp}/AsyncRestThrottled-srt-${srt}-tmt-${tmt}-uc-${uc}-rps-${rps}" \
                                      --report-filename "report.csv" \
                                      --service-url "http://localhost:8888" \
                                      --simulation-class "simulations.AsyncRestThrottled" \
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




# charts
# response length
#   mean rps / rps (threadcount) | mean time / rps (threadcount) | error / rps (threadcount)
#

popd > /dev/null