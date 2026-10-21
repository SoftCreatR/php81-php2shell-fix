#!/usr/bin/env bash
set -euo pipefail
BIN_ROOT="$(cd -- "${1:?Pass the binary directory}" && pwd)"
PHP_BUILD_VERSION="${PHP_BUILD_VERSION:-8.1.34-php2shell.1}"
TEST_ROOT="$(mktemp -d)"
cleanup() {
  if [[ -n "${FPM_PID:-}" ]]; then kill "${FPM_PID}" 2>/dev/null || true; wait "${FPM_PID}" 2>/dev/null || true; fi
  rm -rf -- "${TEST_ROOT}"
}
trap cleanup EXIT
# FPM uses a Unix socket to avoid fixed/shared network ports during CI.
printf '[global]\nerror_log=%s/error.log\n[www]\nlisten=%s/fpm.sock\nuser=nobody\ngroup=nogroup\npm=static\npm.max_children=1\ncatch_workers_output=yes\n' "${TEST_ROOT}" "${TEST_ROOT}" > "${TEST_ROOT}/fpm.conf"
printf '<?php echo PHP_VERSION, "\\n"; if (isset($_GET["oom"])) { ini_set("memory_limit", "16M"); $blocks=[]; while(true) {$blocks[]=str_repeat("x",1048576);} }' > "${TEST_ROOT}/request.php"
chmod 0755 "${TEST_ROOT}"
chmod 0644 "${TEST_ROOT}/request.php"
"${BIN_ROOT}/php-fpm" -n --fpm-config "${TEST_ROOT}/fpm.conf" --nodaemonize --allow-to-run-as-root &
FPM_PID=$!
for _ in $(seq 1 100); do [[ -S "${TEST_ROOT}/fpm.sock" ]] && break; sleep 0.1; done
test -S "${TEST_ROOT}/fpm.sock"
command -v cgi-fcgi >/dev/null
request() { SCRIPT_FILENAME="${TEST_ROOT}/request.php" REQUEST_METHOD=GET QUERY_STRING="${1:-}" timeout 15s cgi-fcgi -bind -connect "${TEST_ROOT}/fpm.sock"; }
for _ in $(seq 1 5); do
  request | grep -q "${PHP_BUILD_VERSION}"
  # The backport may terminate the exhausted worker, so FastCGI can report an
  # application error or connection reset. Require a NEW memory-limit error
  # for every cycle, followed by a successful request, instead of exit status 0.
  memory_errors_before=$(grep -Ec 'Allowed memory size of .* exhausted' "${TEST_ROOT}/error.log" || true)
  oom_status=0
  request oom=1 > "${TEST_ROOT}/oom-response.txt" || oom_status=$?
  for _ in $(seq 1 50); do
    memory_errors_after=$(grep -Ec 'Allowed memory size of .* exhausted' "${TEST_ROOT}/error.log" || true)
    (( memory_errors_after > memory_errors_before )) && break
    sleep 0.1
  done
  if (( memory_errors_after <= memory_errors_before || oom_status == 124 || oom_status == 137 )); then
    echo "Expected a bounded PHP memory-limit error (FastCGI status: ${oom_status})" >&2
    cat "${TEST_ROOT}/oom-response.txt" "${TEST_ROOT}/error.log" >&2
    exit 1
  fi
  request | grep -q "${PHP_BUILD_VERSION}"
done
if grep -Eqi 'segfault|SIGSEGV|SIGBUS|core dumped' "${TEST_ROOT}/error.log"; then
  echo 'A memory-safety crash was reported by the FPM worker' >&2
  exit 1
fi
echo 'FPM: normal and post-OOM requests passed'
