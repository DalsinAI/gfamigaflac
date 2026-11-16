#!/bin/sh
# Host test for scripts/write-part.sh: the Part file GFOpenUpTool reads.
# Copyright (c) 2026 AmiCradle Team. GPL 2 or later, like the FLAC tools.
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir -p "$T/C" "$T/Docs/FLAC"
: > "$T/C/flac"; : > "$T/C/metaflac"; : > "$T/Docs/FLAC/COPYING.GPL"
sh "$HERE/../scripts/write-part.sh" "$T" 1.5.0
fail=0
expect() { grep -qxF "$1" "$T/Part" || { echo "FAIL: no line: $1"; fail=1; }; }
expect 'part FLAC 1.5.0'
expect 'needs 68040'
expect 'copy "C/flac" "SYS:C/flac"'
expect 'copy "C/metaflac" "SYS:C/metaflac"'
expect 'copy "Docs/FLAC/COPYING.GPL" "SYS:Docs/FLAC/COPYING.GPL"'
grep -q 'needs part' "$T/Part" && { echo "FAIL: the tools need no other part"; fail=1; }
[ "$(grep -c '^copy' "$T/Part")" = 3 ] || { echo "FAIL: copy count (the Part file itself must not be listed)"; fail=1; }
sh "$HERE/../scripts/write-part.sh" "$T" 1.5.0
[ "$(grep -c '^copy' "$T/Part")" = 3 ] || { echo "FAIL: second run lists the Part file"; fail=1; }
[ $fail = 0 ] && echo "Part file: all checks passed"
exit $fail
