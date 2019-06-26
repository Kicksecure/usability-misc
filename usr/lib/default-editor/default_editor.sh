#!/bin/sh

## Sets mousepad as the default editor for sudoedit.

if [ "$SUDO_EDITOR" = "" ]; then
   if command -v mousepad &>/dev/null ; then
      SUDO_EDITOR="mousepad"
      export SUDO_EDITOR
   fi
fi
