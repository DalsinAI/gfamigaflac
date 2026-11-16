/* GFAmigaFLAC: the stack libnix's start-up sets up (a Shell gives 4 KB, the
 * encoder's analysis wants more) and the version string.
 * Copyright (c) 2026 AmiCradle Team. GPL 2 or later, like the FLAC tools. */
unsigned long __stack = 256 * 1024;
static const char ver[] __attribute__((used)) = "$VER: FLAC 1.5.0 (16.11.2026) GFAmigaFLAC";
