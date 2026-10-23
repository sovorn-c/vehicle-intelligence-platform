#!/usr/bin/env bash
# Start an Azure Container Apps job and wait for its execution to finish.
# Usage: run-aca-job.sh <resource-group> <job-name>
# Env: JOB_TIMEOUT_SECONDS (default 1800), POLL_SECONDS (default 10).
# Exit: 0 Succeeded; 1 Failed/Stopped/Degraded; 124 timeout.
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "usage: $0 <resource-group> <job-name>" >&2
  exit 2
fi

rg="$1"
job="$2"
timeout_s="${JOB_TIMEOUT_SECONDS:-1800}"
poll_s="${POLL_SECONDS:-10}"

exec_name="$(az containerapp job start -g "${rg}" -n "${job}" --query name -o tsv)"
echo "Started ${job} execution ${exec_name}"

deadline=$((SECONDS + timeout_s))
while :; do
  status="$(az containerapp job execution show -g "${rg}" -n "${job}" \
    --job-execution-name "${exec_name}" --query properties.status -o tsv)"
  echo "${job}/${exec_name}: ${status}"
  case "${status}" in
    Succeeded) exit 0 ;;
    Failed | Stopped | Degraded)
      echo "${job} execution ${exec_name} ended with status ${status}" >&2
      exit 1
      ;;
  esac
  if ((SECONDS >= deadline)); then
    echo "${job} execution ${exec_name} timed out after ${timeout_s}s (last status ${status})" >&2
    exit 124
  fi
  sleep "${poll_s}"
done
