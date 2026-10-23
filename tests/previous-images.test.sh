#!/usr/bin/env bash
# Offline test for scripts/previous-images.sh.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script="${root}/scripts/previous-images.sh"

fail() { echo "FAIL: $*" >&2; exit 1; }

digest="ghcr.io/sovorn-c/vehicle-mcp-server@sha256:$(printf 'b%.0s' {1..64})"
fixture="$(jq -n --arg d "${digest}" '{
  deployed_images: {value: {
    pipeline_image: "ghcr.io/sovorn-c/p@sha256:aa",
    mcp_image: $d,
    agent_image: "ghcr.io/sovorn-c/a@sha256:cc"}}}')"

rc=0
out="$(printf '%s' "${fixture}" | bash "${script}")" || rc=$?
[[ ${rc} -eq 0 ]] || fail "fixture exited ${rc}"
[[ "$(jq -r .mcp_image <<< "${out}")" == "${digest}" ]] || fail "mcp_image mismatch"
[[ "$(jq -r 'keys | join(",")' <<< "${out}")" == "agent_image,mcp_image,pipeline_image" ]] || fail "unexpected keys"

rc=0
out="$(printf '{}' | bash "${script}")" || rc=$?
[[ ${rc} -eq 3 ]] || fail "{} exited ${rc}"
[[ -z "${out}" ]] || fail "{} produced output"

rc=0
out="$(printf '' | bash "${script}")" || rc=$?
[[ ${rc} -eq 3 ]] || fail "empty exited ${rc}"
[[ -z "${out}" ]] || fail "empty produced output"

echo "previous-images.test: OK"
