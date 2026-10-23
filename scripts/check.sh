#!/usr/bin/env bash
# Repository preflight: formatting, validation, lint, offline tests, scripts.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

roots=(terraform/bootstrap terraform/stack)

echo "==> terraform fmt"
terraform fmt -check -recursive

for root in "${roots[@]}"; do
  echo "==> terraform init/validate: ${root}"
  terraform -chdir="${root}" init -backend=false -input=false
  terraform -chdir="${root}" validate
done

echo "==> tflint"
tflint --init
tflint --recursive

for root in "${roots[@]}"; do
  if [[ -d "${root}/tests" ]]; then
    echo "==> terraform test: ${root}"
    terraform -chdir="${root}" test
  fi
done

if [[ -d .github/workflows ]]; then
  echo "==> actionlint"
  actionlint
fi

shopt -s nullglob
shell_files=(scripts/*.sh tests/*.sh)
if ((${#shell_files[@]} > 0)); then
  echo "==> shellcheck"
  shellcheck "${shell_files[@]}"
fi

for t in tests/*.test.sh; do
  echo "==> ${t}"
  bash "${t}"
done

echo "check: OK"
