#!/bin/sh

## Copyright (C) 2026 - 2026 ENCRYPTED SUPPORT LLC <adrelanos@whonix.org>
## See the file COPYING for copying conditions.

## style-ok: no-strict (sourced-only '/etc/profile.d' fragment; a top-level
## R-010 strict-mode block would leak 'set -o errexit'/'nounset' into, and
## could kill, the interactive login shell).

## See also:
## /etc/profile
## /etc/profile.d/safe-rm

## Scope: '/etc/profile.d' is sourced only by login shells (via
## '/etc/profile'). Non-login shells (GUI terminals, systemd --user
## services, cron, non-login ssh) do not source it. This is fine because
## PATH is exported once by the session's top login shell and inherited by
## all child processes; it is deliberately NOT re-applied for non-login
## shells. Contexts that never descend from a login shell set their own
## PATH and are out of scope here.

## No need to prepend '/usr/local/sbin:/usr/sbin:/sbin' when running as root,
## because Debian' default '/etc/profile' already does that.
if [ "$(id -u)" -ne 0 ]; then
  ## Example PATH:
  ## /usr/share/safe-rm/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games

  ## Not running as root.
  ##
  ## Debian as of Debian trixie did not 'usrmerge' '/etc/profile':
  ## still comes with '/bin' and '/sbin'. Therefore also setting it here for
  ## consistency.
  ##
  ## Why `/sbin`? See:
  ## https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1041357
  ## https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1041357#17
  path_prepend_once() {
    true "$0: path_prepend_once..."
    case ":${PATH:-}:" in
      *":$1:"*)
        true "$0: INFO: $1 is already included in PATH. Not adding duplicate. Ok."
        ;;
      *)
        if [ -n "$PATH" ]; then
          true "$0: INFO: Prepending $1 to PATH."
          PATH="$1:$PATH"
        else
          true "$0: INFO: Setting PATH=$1"
          PATH="$1"
        fi
        ;;
    esac
  }
  path_prepend_once /sbin
  path_prepend_once /usr/sbin
  path_prepend_once /usr/local/sbin

  ## Do not leak the helper into the sourcing login shell's function
  ## namespace ('/etc/profile' itself models this cleanup with 'unset i').
  unset -f path_prepend_once

  ## Implemented using 'debian/usability-misc.hide' instead.
  #true "INFO: Removing /usr/share/safe-rm/bin from PATH."
  ## In case we wanted to keep 'safe-rm' in 'PATH'.
  #PATH="/usr/local/sbin:/usr/sbin:/sbin:$PATH"
  ## Remove 'safe-rm' from 'PATH'.
  ## 'str_replace' lacks the regex anchoring needed to remove elements
  ## from colon-separated variables safely.
  ## '<<<' unsupported by 'sh'.
  #PATH="$(sed 's#:/usr/share/safe-rm/bin$##; s#^/usr/share/safe-rm/bin:##; s#:/usr/share/safe-rm/bin:#:#' <<< "$PATH")"
  #PATH="$(printf '%s\n' "$PATH" | sed 's#:/usr/share/safe-rm/bin$##; s#^/usr/share/safe-rm/bin:##; s#:/usr/share/safe-rm/bin:#:#')"

  ## Example PATH:
  ## /usr/local/sbin:/usr/sbin:/sbin:/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games

  export PATH

  if [ "$PATH" = "/usr/local/sbin:/usr/sbin:/sbin:/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games" ]; then
    true "INFO: Expected default PATH: yes"
  else
    true "INFO: Expected default PATH: no (customized PATH)"
  fi
fi
