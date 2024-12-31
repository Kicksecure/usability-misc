#!/bin/sh

## Copyright (C) 2019 - 2025 ENCRYPTED SUPPORT LLC <adrelanos@whonix.org>
## See the file COPYING for copying conditions.

#### meta start
#### project Kicksecure
#### category apps
#### description
## Source <code>/usr/libexec/default-editor/default_editor.sh</code>, if it is
## executable.
##
## Add <code>/usr/share/usability-misc/xdg-override/</code> to
## <code>XDG_CONFIG_DIRS</code> environment variable.
#### meta end

if [ -x /usr/libexec/default-editor/default_editor.sh ]; then
   . /usr/libexec/default-editor/default_editor.sh
fi

if [ -z "$XDG_DATA_DIRS" ]; then
   XDG_DATA_DIRS=/usr/local/share/:/usr/share/
fi
if ! echo "$XDG_DATA_DIRS" | grep --quiet /usr/share/usability-misc/xdg-override/ ; then
   export XDG_DATA_DIRS=/usr/share/usability-misc/xdg-override/:$XDG_DATA_DIRS
fi
