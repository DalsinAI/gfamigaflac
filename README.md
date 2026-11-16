# GFAmigaFLAC

FLAC 1.5.0's command-line tools for GFOS (AmigaOS 3.2.3 with GFOpenUp) on a
68040: `flac` turns WAV, AIFF, RF64 and Wave64 into lossless FLAC and back,
and tests FLAC files; `metaflac` reads and writes their tags, pictures, seek
tables and ReplayGain. Both come in the GFOpenUp part **FLAC**:

    GFOpenUpTool INSTALL Parts/FLAC

    flac -8 Work:Samples/loop.wav          ; makes loop.flac beside it
    flac -t Work:Samples/loop.flac
    flac -d -o RAM:loop.wav Work:Samples/loop.flac
    metaflac --set-tag="ARTIST=Café Amiga" Work:Samples/loop.flac
    metaflac --list Work:Samples/loop.flac

Tags you type in a Shell are Latin-1, the Amiga's own text; FLAC keeps them
as UTF-8 inside the file and gives them back as Latin-1 (set `CHARSET` to say
otherwise). Files up to 2 GB. Ogg FLAC is not built.

## Building

    STOVE=~/AmiCradle/kitchen/stoves/os32-gcc16-open6 OUT=out ./build-amiga.sh

FLAC is fetched at the commit `flac.lock` pins and patched from `patches/`
(utime in place of utimensat, which libnix lacks; Latin-1 as the default
charset and the console's width, one column a byte); `compat/config.h` stands for FLAC's configure. It builds with soft
float, taking the FPU where there is one (fpuauto), on one thread.

## Tests

    make -C tests test

builds patched FLAC for the host and sends a 16-bit stereo WAV and an 8-bit
mono AIFF through `flac` and back bit for bit, checks the decoded file keeps
its date, and has `metaflac` write, read and remove a Latin-1 tag.

Designed, tested and delivered by The AmiCradle Team.
FLAC is Copyright (c) Josh Coalson and the Xiph.Org Foundation: the tools
under the GPL 2 or later, libFLAC under Xiph's BSD licence.
