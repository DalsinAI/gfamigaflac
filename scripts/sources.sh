# The FLAC 1.5.0 sources flac and metaflac are built from (FLAC's own
# Makefile.am lists, without Ogg, the x86/ARM intrinsics and Windows' UTF-8
# layer).  Sourced by build-amiga.sh and tests/run-host-tests.sh.
# Copyright (c) 2026 AmiCradle Team. GPL 2 or later, like the FLAC tools.
LIBFLAC="bitmath bitreader bitwriter cpu crc fixed float format lpc md5 memory
 metadata_iterators metadata_object stream_decoder stream_encoder stream_encoder_framing window"
SHARE="getopt/getopt getopt/getopt1 grabbag/alloc grabbag/cuesheet grabbag/file grabbag/picture
 grabbag/replaygain grabbag/seektable grabbag/snprintf replaygain_analysis/replaygain_analysis
 replaygain_synthesis/replaygain_synthesis utf8/charset utf8/iconvert utf8/utf8"
FLACTOOL="analyze decode encode foreign_metadata main local_string_utils utils vorbiscomment"
METAFLAC="main operations operations_shorthand_cuesheet operations_shorthand_picture
 operations_shorthand_seektable operations_shorthand_streaminfo operations_shorthand_vorbiscomment
 options usage utils"
