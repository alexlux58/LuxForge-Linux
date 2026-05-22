#!/usr/bin/env bash
set -euo pipefail

fail=0

check_cmd() {
  local name="$1"
  local cmd="$2"
  if command -v "$cmd" >/dev/null 2>&1; then
    printf "[OK]   %s -> %s\n" "$name" "$(command -v "$cmd")"
  else
    printf "[FAIL] %s missing\n" "$name"
    fail=1
  fi
}

echo "== Basic command presence =="
check_cmd bash bash
check_cmd ld ld
check_cmd bison bison
check_cmd sort sort
check_cmd diff diff
check_cmd find find
check_cmd gawk gawk
check_cmd gcc gcc
check_cmd g++ g++
check_cmd grep grep
check_cmd gzip gzip
check_cmd m4 m4
check_cmd make make
check_cmd patch patch
check_cmd perl perl
check_cmd python3 python3
check_cmd sed sed
check_cmd tar tar
check_cmd texi2any texi2any
check_cmd xz xz

echo
echo "== Kernel =="
uname -r

echo
echo "== Shell/link sanity =="
readlink -f /bin/sh || true
readlink -f /usr/bin/awk || true
readlink -f /usr/bin/yacc || true

echo
echo "== PTY support =="
if mount | grep -q 'devpts on /dev/pts' && [ -e /dev/ptmx ]; then
  echo "[OK]   UNIX98 PTY appears available"
else
  echo "[FAIL] PTY support check failed"
  fail=1
fi

echo
echo "== Compiler sanity =="
compiler_test_binary="$(mktemp "${TMPDIR:-/tmp}/lfs-compiler-check.XXXXXX")"
trap 'rm -f "$compiler_test_binary"' EXIT
printf 'int main(){return 0;}\n' | g++ -x c++ - -o "$compiler_test_binary" >/dev/null 2>&1 \
  && echo "[OK]   g++ compile works" \
  || { echo "[FAIL] g++ compile failed"; fail=1; }
printf 'int main(){return 0;}\n' | g++ -x c++ - -o /tmp/lfs-compiler-check >/dev/null 2>&1 \
  && echo "[OK]   g++ compile works" \
  || { echo "[FAIL] g++ compile failed"; fail=1; }
rm -f /tmp/lfs-compiler-check

echo
echo "== CPU cores =="
nproc || true

exit $fail
