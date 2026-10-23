#!/usr/bin/env bash
# Offline test for scripts/run-aca-job.sh using a fake az on PATH.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script="${root}/scripts/run-aca-job.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT
mkdir -p "${tmp}/bin"

# Fake az: `job start` prints an execution name; `execution show` pops the next
# status from FAKE_STATUSES (the last one repeats forever).
cat > "${tmp}/bin/az" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
case "$*" in
  *"job start"*) echo "exec-1" ;;
  *"job execution show"*)
    read -r -a statuses <<< "${FAKE_STATUSES}"
    idx=0
    [[ -f "${FAKE_STATE}" ]] && idx="$(cat "${FAKE_STATE}")"
    last=$((${#statuses[@]} - 1))
    ((idx > last)) && idx=${last}
    echo "${statuses[idx]}"
    echo $((idx + 1)) > "${FAKE_STATE}"
    ;;
  *) echo "unexpected az call: $*" >&2; exit 99 ;;
esac
FAKE
chmod +x "${tmp}/bin/az"

fail() { echo "FAIL: $*" >&2; exit 1; }

run() { # statuses; sets rc, err
  rm -f "${tmp}/state"
  rc=0
  PATH="${tmp}/bin:${PATH}" FAKE_STATE="${tmp}/state" FAKE_STATUSES="$1" \
    POLL_SECONDS=1 JOB_TIMEOUT_SECONDS="${2:-30}" \
    bash "${script}" rg job > "${tmp}/out" 2> "${tmp}/err" || rc=$?
}

run "Running Running Succeeded"
[[ ${rc} -eq 0 ]] || fail "success case exited ${rc}"

run "Running Failed"
[[ ${rc} -eq 1 ]] || fail "failed case exited ${rc}"
grep -q "Failed" "${tmp}/err" || fail "stderr missing Failed"

start=${SECONDS}
run "Running" 2
elapsed=$((SECONDS - start))
[[ ${rc} -eq 124 ]] || fail "timeout case exited ${rc}"
((elapsed <= 5)) || fail "timeout took ${elapsed}s"

echo "run-aca-job.test: OK"
