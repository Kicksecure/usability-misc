#!/bin/sh

## Sets mousepad as the default editor for sudoedit if environment variable
## SUDO_EDITOR is unset and if mousepad is installed.

if [ "$SUDO_EDITOR" = "" ]; then
   if command -v mousepad 1>/dev/null 2>/dev/null  ; then
      SUDO_EDITOR="mousepad"
      export SUDO_EDITOR
   fi
fi
