#!/usr/bin/env bash
# Read `terraform output -json` on stdin; print the previously deployed images
# as a tfvars JSON object. Exit 3 (no output) when none are recorded.
set -euo pipefail

input="$(cat)"
if [[ -z "${input//[[:space:]]/}" ]]; then
  exit 3
fi

out="$(jq -c '
  .deployed_images.value
  | select(type == "object"
           and (.pipeline_image | type == "string")
           and (.mcp_image | type == "string")
           and (.agent_image | type == "string"))
  | {pipeline_image, mcp_image, agent_image}' <<< "${input}")"

if [[ -z "${out}" ]]; then
  exit 3
fi
echo "${out}"
