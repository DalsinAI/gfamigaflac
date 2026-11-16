/* config.h for FLAC 1.5.0 on GFOS (AmigaOS 3.2.3, 68040, libnix): what
 * FLAC's CMake would find there.  Host tests build with GFAMIGA_HOST_TEST,
 * which only flips the byte order to the host's.
 * Copyright (c) 2026 AmiCradle Team. GPL 2 or later, like the FLAC tools. */
#ifndef GFAMIGA_FLAC_CONFIG_H
#define GFAMIGA_FLAC_CONFIG_H

#ifdef GFAMIGA_HOST_TEST
#define CPU_IS_BIG_ENDIAN 0
#else
#define CPU_IS_BIG_ENDIAN 1
#endif
#define WORDS_BIGENDIAN CPU_IS_BIG_ENDIAN
/* 32-bit bit-buffer words: the 68040's own width */
#define ENABLE_64_BIT_WORDS 0
#define OGG_FOUND 0
#define FLAC__HAS_OGG 0
#define FLAC__HAS_X86INTRIN 0
#define FLAC__HAS_NEONINTRIN 0
#define FLAC__HAS_A64NEONINTRIN 0
#define HAVE_LROUND 1
#define HAVE_INTTYPES_H 1
#define HAVE_STDINT_H 1
#define HAVE_STDLIB_H 1
#define HAVE_STRING_H 1
#define HAVE_SYS_STAT_H 1
#define HAVE_SYS_TYPES_H 1
#define HAVE_UNISTD_H 1
/* not on libnix: fseeko (fseek/ftell, files up to 2 GB), getopt_long (FLAC's
 * own share/getopt), iconv (FLAC's own charset tables), nl_langinfo,
 * ioctl/termios (no console width), clock_gettime, and pthreads: libFLAC 1.5's
 * multithreaded encoder stays off, one thread as on a 68040 it should */
#define PACKAGE_VERSION "1.5.0"
#define FLAC__NO_DLL 1
#endif
