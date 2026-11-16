#!/bin/sh
# Builds FLAC's command-line tools, flac and metaflac, for GFOS (AmigaOS
# 3.2.3 with GFOpenUp) with a stove: 68040, soft float with the FPU taken
# when there is one (fpuauto), one thread.
#   STOVE=.../stoves/os32-gcc16-open6 OUT=out ./build-amiga.sh
# FLAC and fpuauto are fetched at the commits flac.lock gives and FLAC is
# patched with patches/; nothing third-party is kept here. The build tree is
# kept, so a run that stops at BUDGET_TOTAL seconds goes on next time.
# OUT gets Parts/FLAC: a GFOpenUp part (its Part file, C/flac, C/metaflac and
# the licences and readme under Docs/FLAC), installed with
#   GFOpenUpTool INSTALL Parts/FLAC
# Copyright (c) 2026 AmiCradle Team. GPL 2 or later, like the FLAC tools.
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/flac.lock"; . "$HERE/scripts/sources.sh"
STOVE=${STOVE:-"$HOME/AmiCradle/stoves/os32-gcc16-open6"}
# outside the checkout: Cradle cleans it (git clean -ffdx) before every job
WORK="${WORK:-$HOME/.cache/gfamigaflac/build}"; OUT="${OUT:-$WORK/out}"; JOBS=${JOBS:-12}
TC="$STOVE/prefix"; PATH="$TC/bin:$PATH"; export PATH
mkdir -p "$WORK/deps" "$OUT"; OUT=$(cd "$OUT" && pwd)
t0=$(date +%s)

# a repository at one commit, fetched once (SPARSE: only those folders)
fetch() {
    d="$WORK/deps/$1"
    if [ "$(git -C "$d" rev-parse HEAD 2>/dev/null)" != "$3" ]; then
        rm -rf "${d:?}"; mkdir -p "$d"
        git -C "$d" init -q
        if [ -n "${4:-}" ]; then
            git -C "$d" config core.sparseCheckout true
            echo "$4" > "$d/.git/info/sparse-checkout"
            git -C "$d" fetch -q --depth 1 --filter=blob:none "$2" "$3"
        else
            git -C "$d" fetch -q --depth 1 "$2" "$3"
        fi
        git -C "$d" checkout -q FETCH_HEAD
        [ "$(git -C "$d" rev-parse HEAD)" = "$3" ] || { echo "$1: commit mismatch"; exit 1; }
    fi
}

# --- fpuauto: libfpuauto.a and its link specs ---------------------------------
fetch fpuauto "$FPA_REPO" "$FPA_COMMIT" "/common/fpuauto/"
FA="$WORK/deps/fpuauto/common/fpuauto"; FAL="$WORK/fpuauto"
if [ ! -f "$FAL/libfpuauto.a" ] || [ "$(cat "$FAL/.rev" 2>/dev/null)" != "$FPA_COMMIT" ]; then
    rm -rf "$FAL"; mkdir -p "$FAL/obj"
    m68k-amigaos-gcc -m68040 -DFPUAUTO_COMMON -c "$FA/fpuauto.S" -o "$FAL/obj/fa_common.o"
    for n in $(sed 's/^--wrap=//' "$FA/fpuauto.wraps"); do
        m68k-amigaos-gcc -m68040 -DR_$n -c "$FA/fpuauto.S" -o "$FAL/obj/fa_$n.o"
    done
    m68k-amigaos-ar rcs "$FAL/libfpuauto.a" "$FAL"/obj/fa_*.o
    echo "$FPA_COMMIT" > "$FAL/.rev"
fi

# --- FLAC at its pinned commit, with patches/ ----------------------------------
SRC="$WORK/flac"
PSUM=$(cat "$HERE"/patches/*.patch | sha256sum | cut -c1-16)
if [ "$(cat "$SRC/.patched" 2>/dev/null)" != "$FLAC_COMMIT-$PSUM" ]; then
    rm -rf "$SRC"; mkdir -p "$SRC"
    git -C "$SRC" init -q
    git -C "$SRC" fetch -q --depth 1 "$FLAC_GIT" "$FLAC_COMMIT"
    git -C "$SRC" checkout -q FETCH_HEAD
    [ "$(git -C "$SRC" rev-parse HEAD)" = "$FLAC_COMMIT" ] || { echo "commit mismatch"; exit 1; }
    for p in "$HERE"/patches/*.patch; do
        patch -s -d "$SRC" -p1 < "$p" || { echo "patch failed: $p"; exit 1; }
    done
    echo "$FLAC_COMMIT-$PSUM" > "$SRC/.patched"
fi

# --- one Makefile ------------------------------------------------------------------
CF="-noixemul -m68040 -O2 -fno-delete-null-pointer-checks -D__amigaos__ -DNDEBUG -DHAVE_CONFIG_H
 -I$HERE/compat -I$SRC/include -I$SRC/src/libFLAC/include -Wno-deprecated-declarations"
O="$WORK/obj"; mkdir -p "$O"
{
    echo "CF = $(echo $CF)"
    L=""; F=""; M=""
    rule() {  # rule <object> <source>
        printf '%s: %s\n\tm68k-amigaos-gcc $(CF) -MMD -c $< -o $@\n' "$1" "$2"
    }
    for f in $LIBFLAC; do rule "l_$f.o" "$SRC/src/libFLAC/$f.c"; L="$L l_$f.o"; done
    for f in $SHARE; do o="s_$(echo $f | tr / _).o"; rule "$o" "$SRC/src/share/$f.c"; L="$L $o"; done
    rule c_amiga_compat.o "$HERE/compat/amiga_compat.c"; L="$L c_amiga_compat.o"
    for f in $FLACTOOL; do rule "f_$f.o" "$SRC/src/flac/$f.c"; F="$F f_$f.o"; done
    for f in $METAFLAC; do rule "m_$f.o" "$SRC/src/metaflac/$f.c"; M="$M m_$f.o"; done
    echo "LOBJS =$L"; echo "FOBJS =$F"; echo "MOBJS =$M"
    echo "all: \$(LOBJS) \$(FOBJS) \$(MOBJS)"
    echo "-include *.d"
} > "$O/Makefile"
left=$(( ${BUDGET_TOTAL:-840} - ($(date +%s) - t0) ))
[ "$left" -gt 60 ] || { echo "no time left this run"; exit 0; }
set +e
(cd "$O" && timeout "$left" nice -n 19 make -k -j"$JOBS" all > make.log 2>&1)
rc=$?
set -e
grep -E -B2 'error|Error' "$O/make.log" | head -80
[ "$rc" = 0 ] || { [ "$rc" = 124 ] && echo "out of time: run again to go on"; tail -20 "$O/make.log"; echo "compile: $(( $(date +%s) - t0 )) s"; exit "$rc"; }
echo "compile: $(( $(date +%s) - t0 )) s, $(ls "$O"/*.o | wc -l) objects"

# --- the links: soft-float specs, then fpuauto's -------------------------------------
LINK="m68k-amigaos-gcc -noixemul -m68040 -specs=$HERE/scripts/m68k-soft-m68040.specs -specs=$FA/fpuauto.specs -L$FAL"
objs() { for f in $(sed -n "s/^$1 =//p" "$O/Makefile"); do echo "$O/$f"; done; }
# shellcheck disable=SC2046
$LINK -o "$O/flac.debug" $(objs FOBJS) $(objs LOBJS) -lm > "$O/link.log" 2>&1 || { head -60 "$O/link.log"; exit 1; }
# shellcheck disable=SC2046
$LINK -o "$O/metaflac.debug" $(objs MOBJS) $(objs LOBJS) -lm >> "$O/link.log" 2>&1 || { head -60 "$O/link.log"; exit 1; }

# --- the GFOpenUp part: Parts/FLAC ----------------------------------------------------
P="$OUT/Parts/FLAC"; rm -rf "$P"; mkdir -p "$P/C" "$P/Docs/FLAC"
m68k-amigaos-strip -o "$P/C/flac" "$O/flac.debug"
m68k-amigaos-strip -o "$P/C/metaflac" "$O/metaflac.debug"
cp "$SRC/COPYING.GPL" "$P/Docs/FLAC/COPYING.GPL"
cp "$SRC/COPYING.Xiph" "$P/Docs/FLAC/COPYING.Xiph"
cp "$HERE/README.md" "$P/Docs/FLAC/ReadMe"
sh "$HERE/scripts/write-part.sh" "$P" "$FLAC_VERSION"
ls -l "$P/C"
echo "part: $(grep -c '^copy' "$P/Part") files, $(du -sk "$P" | cut -f1) KB"
echo "fpuauto: $(m68k-amigaos-nm "$O/flac.debug" | grep -c ' T ___wrap_') wrapped routines in flac"
echo "total: $(( $(date +%s) - t0 )) s"
