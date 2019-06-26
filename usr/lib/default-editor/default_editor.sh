#!/bin/sh

## Sets mousepad as the default editor for sudoedit.

if [ "$SUDO_EDITOR" = "" ]; then
   SUDO_EDITOR="mousepad"
   export SUDO_EDITOR
fi
