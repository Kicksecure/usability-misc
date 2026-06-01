#!/bin/sh

## Copyright (C) 2026 - 2026 ENCRYPTED SUPPORT LLC <adrelanos@whonix.org>
## See the file COPYING for copying conditions.

## See also:
## /etc/profile
## /etc/profile.d/safe-rm

## No need to prepend '/usr/local/sbin:/usr/sbin:/sbin' when running as root,
## because Debian' default '/etc/profile' already does that.
if ! [ "$(id -u)" -eq 0 ]; then
  ## Not running as root.
  ##
  ## Debian as of Debian trixie did not 'usrmerge' '/etc/profile':
  ## still comes with '/bin' and '/sbin'. Therefore also setting it here for
  ## consistency.
  ##
  ## Why `/sbin`? See:
  ## https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1041357
  ## https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1041357#17
  ##
  ## In case we wanted to keep 'safe-rm' in 'PATH'.
  #PATH="/usr/local/sbin:/usr/sbin:/sbin:$PATH"
  ## Remove 'safe-rm' from 'PATH'.
  ## 'str_replace' lacks the regex anchoring needed to remove elements
  ## from colon-separated variables safely.
  PATH="$(sed 's#:/usr/share/safe-rm/bin$##; s#^/usr/share/safe-rm/bin:##; s#:/usr/share/safe-rm/bin:#:#' <<< "$PATH")"
  export PATH
fi
