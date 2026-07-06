#!/usr/bin/env bash
set -euo pipefail

# Runs the load test in non-GUI (CLI) mode and generates an HTML dashboard
# report. Running in GUI mode is fine for building/debugging a test plan,
# but Apache JMeter's own docs warn against using GUI mode for actual load
# generation — it's far less resource-efficient than CLI mode.
#
# Usage:
#   ./scripts/run-load-test.sh [threads] [rampup_seconds] [loops]
#
# Examples:
#   ./scripts/run-load-test.sh              # defaults: 10 threads, 10s ramp-up, 5 loops
#   ./scripts/run-load-test.sh 50 20 10      # 50 threads, 20s ramp-up, 10 loops each

THREADS="${1:-10}"
RAMPUP="${2:-10}"
LOOPS="${3:-5}"

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULTS_DIR="results"
REPORT_DIR="reports/${TIMESTAMP}"

mkdir -p "$RESULTS_DIR" "reports"

if ! command -v jmeter &> /dev/null; then
  echo "Error: 'jmeter' is not on your PATH." >&2
  echo "Download Apache JMeter from https://jmeter.apache.org/download_jmeter.cgi" >&2
  echo "and add its bin/ directory to your PATH." >&2
  exit 1
fi

echo "Running load test: threads=$THREADS rampup=${RAMPUP}s loops=$LOOPS"
echo ""

jmeter -n \
  -t test-plans/reqres-api-load-test.jmx \
  -l "${RESULTS_DIR}/results-${TIMESTAMP}.jtl" \
  -e -o "$REPORT_DIR" \
  -Jthreads="$THREADS" \
  -Jrampup="$RAMPUP" \
  -Jloops="$LOOPS"

echo ""
echo "Done."
echo "Raw results: ${RESULTS_DIR}/results-${TIMESTAMP}.jtl"
echo "HTML report: ${REPORT_DIR}/index.html"
