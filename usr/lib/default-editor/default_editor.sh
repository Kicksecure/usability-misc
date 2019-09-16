#!/bin/sh

## Copyright (C) 2019 - 2019 ENCRYPTED SUPPORT LP <adrelanos@riseup.net>
## See the file COPYING for copying conditions.

## Sets mousepad as the default editor for VISUAL if environment variable
## VISUAL is unset and if mousepad is installed.

## please provide /usr/bin/visual
## https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=758228

if [ "$VISUAL" = "" ]; then
   if command -v mousepad 1>/dev/null 2>/dev/null  ; then
      VISUAL="mousepad"
      export VISUAL
   fi
fi
