#!/bin/sh
# Host tests: FLAC with patches/ and compat/config.h (byte order flipped to the
# host's, GFAMIGA_HOST_TEST) built for the host from scripts/sources.sh, then
#  - a 16-bit stereo WAV and an 8-bit mono AIFF go through flac and back, bit
#    for bit, with -t passing on each .flac;
#    and the decoded file keeps the .flac's date;
#  - metaflac writes, lists and removes a Vorbis comment with Latin-1 text
#    (the Amiga's charset: utf8.c falls back to ISO-8859-1 with -D__amigaos__).
#   sh tests/run-host-tests.sh      (WORK=... to keep the checkout elsewhere)
# Copyright (c) 2026 AmiCradle Team. GPL 2 or later, like the FLAC tools.
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$HERE/flac.lock"; . "$HERE/scripts/sources.sh"
WORK=${WORK:-$(mktemp -d)}
SRC="$WORK/flac"
if [ "$(git -C "$SRC" rev-parse HEAD 2>/dev/null)" != "$FLAC_COMMIT" ]; then
    rm -rf "$SRC"; mkdir -p "$SRC"; git -C "$SRC" init -q
    git -C "$SRC" fetch -q --depth 1 "$FLAC_GIT" "$FLAC_COMMIT"; git -C "$SRC" checkout -q FETCH_HEAD
    for p in "$HERE"/patches/*.patch; do patch -s -d "$SRC" -p1 < "$p"; done
fi
O="$WORK/host"; mkdir -p "$O"
CF="-O1 -w -DHAVE_CONFIG_H -DGFAMIGA_HOST_TEST -D__amigaos__ -I$HERE/compat -I$SRC/include -I$SRC/src/libFLAC/include"
objs=""
for f in $LIBFLAC; do cc $CF -c "$SRC/src/libFLAC/$f.c" -o "$O/l_$f.o"; objs="$objs $O/l_$f.o"; done
for f in $SHARE; do o="$O/s_$(echo $f | tr / _).o"; cc $CF -c "$SRC/src/share/$f.c" -o "$o"; objs="$objs $o"; done
fo=""; for f in $FLACTOOL; do cc $CF -c "$SRC/src/flac/$f.c" -o "$O/f_$f.o"; fo="$fo $O/f_$f.o"; done
mo=""; for f in $METAFLAC; do cc $CF -c "$SRC/src/metaflac/$f.c" -o "$O/m_$f.o"; mo="$mo $O/m_$f.o"; done
cc -o "$O/flac" $fo $objs -lm
cc -o "$O/metaflac" $mo $objs -lm
python3 "$HERE/tests/make_audio.py" "$O"
T=$O; fail=0
for a in t16.wav t8.aiff; do
    b=${a%.*}; e=${a##*.}
    "$T/flac" -s -f -8 -o "$T/$b.flac" "$T/$a"
    "$T/flac" -s -t "$T/$b.flac" || { echo "FAIL: flac -t $b.flac"; fail=1; }
    "$T/flac" -s -f -d -o "$T/$b.out.$e" "$T/$b.flac"
    cmp -s "$T/$a" "$T/$b.out.$e" || { echo "FAIL: $a round trip differs"; fail=1; }
    # the decoded file keeps the .flac's date (grabbag's utime, not utimensat)
    [ "$(stat -c %Y "$T/$b.out.$e")" = "$(stat -c %Y "$T/$b.flac")" ] || { echo "FAIL: $b.out.$e date not kept"; fail=1; }
done
"$T/metaflac" --set-tag="TITLE=$(printf 'Caf\351 Amiga')" "$T/t16.flac"
"$T/metaflac" --show-tag=TITLE "$T/t16.flac" > "$T/tag.txt"
printf 'TITLE=Caf\351 Amiga\n' | cmp -s - "$T/tag.txt" || { echo "FAIL: Latin-1 tag: $(od -c "$T/tag.txt" | head -2)"; fail=1; }
"$T/metaflac" --remove-tag=TITLE "$T/t16.flac"
[ -z "$("$T/metaflac" --show-tag=TITLE "$T/t16.flac")" ] || { echo "FAIL: tag not removed"; fail=1; }
"$T/flac" -s -t "$T/t16.flac" || { echo "FAIL: flac -t after metaflac"; fail=1; }
[ $fail = 0 ] && echo "flac and metaflac on the host: all checks passed"
exit $fail
