#!/bin/sh

## Copyright (C) 2019 - 2025 ENCRYPTED SUPPORT LLC <adrelanos@whonix.org>
## See the file COPYING for copying conditions.

## Sets mousepad as the default editor for environment variable 'VISUAL'
## is unset and if mousepad is installed.

## Environment variable 'VISUAL' will also be honored by 'sudoedit'.

## https://forums.whonix.org/t/use-sudoedit-in-whonix-documentation/7599

## please provide /usr/bin/visual
## https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=758228

if [ "$XDG_SESSION_TYPE" = "tty" ]; then
   true "$0: INFO: Running inside tty. Stop."
   return 0
   exit 0
fi

if [ "$VISUAL" = "" ]; then
   if command -v featherpad 1>/dev/null 2>/dev/null ; then
      VISUAL="featherpad"
      export VISUAL
      return 0
      exit 0
   fi
   if command -v mousepad 1>/dev/null 2>/dev/null ; then
      VISUAL="mousepad"
      export VISUAL
      return 0
      exit 0
   fi
fi
