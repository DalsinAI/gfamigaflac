#!/bin/sh
# Writes the Part file GFOpenUpTool INSTALL reads (gfopenup src/openuptool.c):
# one "copy" line per file under the part drawer, each to SYS:<its path>.
#   write-part.sh <part drawer> <version>
# Copyright (c) 2026 AmiCradle Team. GPL 2 or later, like the FLAC tools.
set -eu
P=$1; V=$2
{
    echo "part FLAC $V"
    echo "; FLAC: flac (lossless audio to and from WAV, AIFF, RF64, W64) and metaflac (tags, pictures, seek tables) as shell commands"
    echo "needs 68040"
    (cd "$P" && find C Docs -type f ! -name Part 2>/dev/null | LC_ALL=C sort) | while read -r f; do
        echo "copy \"$f\" \"SYS:$f\""
    done
} > "$P/Part"
