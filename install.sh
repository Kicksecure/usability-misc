#!/bin/sh
## vim: set sw=2 sts=2 ts=2 et :
##
## Copyright (C) 2022 nyxnor <nyxnor@protonmail.com>
## Copyright (C) 2022 grass <grass@danwin1210.de>
## Copyright (C) 2022 ENCRYPTED SUPPORT LP <adrelanos@whonix.org>
##
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <https://www.gnu.org/licenses/>.
##
## On Debian systems, the full text of the GNU General Public
## License version 3 can be found in the file
## `/usr/share/common-licenses/GPL-3'.
##
##########################
## BEGIN DEFAULT VALUES ##
##########################
set -o errexit
set -o nounset

dialog_title="License agreement (scroll with arrows)"
license="
Please do NOT continue unless you understand everything!
 DISCLAIMER OF WARRANTY.
 .
 THE PROGRAM IS PROVIDED WITHOUT ANY WARRANTIES, WHETHER EXPRESSED OR IMPLIED,
 INCLUDING, WITHOUT LIMITATION, IMPLIED WARRANTIES OF FITNESS FOR A PARTICULAR
 PURPOSE, NON-INFRINGEMENT, TITLE AND MERCHANTABILITY.  THE PROGRAM IS BEING
 DELIVERED OR MADE AVAILABLE 'AS IS', 'WITH ALL FAULTS' AND WITHOUT WARRANTY OR
 REPRESENTATION.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
 PROGRAM IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
 ALL NECESSARY SERVICING, REPAIR OR CORRECTION.
 .
 LIMITATION OF LIABILITY.
 .
 UNDER NO CIRCUMSTANCES SHALL ANY COPYRIGHT HOLDER OR ITS AFFILIATES, OR ANY
 OTHER PARTY WHO MODIFIES AND/OR CONVEYS THE PROGRAM AS PERMITTED ABOVE, BE
 LIABLE TO YOU, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, FOR ANY
 DAMAGES OR OTHER LIABILITY, INCLUDING ANY GENERAL, DIRECT, INDIRECT, SPECIAL,
 INCIDENTAL, CONSEQUENTIAL OR PUNITIVE DAMAGES ARISING FROM, OUT OF OR IN
 CONNECTION WITH THE USE OR INABILITY TO USE THE PROGRAM OR OTHER DEALINGS WITH
 THE PROGRAM(INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED
 INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE
 PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS), WHETHER OR NOT ANY COPYRIGHT HOLDER
 OR SUCH OTHER PARTY RECEIVES NOTICE OF ANY SUCH DAMAGES AND WHETHER OR NOT SUCH
 DAMAGES COULD HAVE BEEN FORESEEN.
 .
 INDEMNIFICATION.
 .
 IF YOU CONVEY A COVERED WORK AND AGREE WITH ANY RECIPIENT
 OF THAT COVERED WORK THAT YOU WILL ASSUME ANY LIABILITY FOR THAT COVERED WORK,
 YOU HEREBY AGREE TO INDEMNIFY, DEFEND AND HOLD HARMLESS THE OTHER LICENSORS AND
 AUTHORS OF THAT COVERED WORK FOR ANY DAMAGES, DEMANDS, CLAIMS, LOSSES, CAUSES OF
 ACTION, LAWSUITS, JUDGMENTS EXPENSES (INCLUDING WITHOUT LIMITATION REASONABLE
 ATTORNEYS' FEES AND EXPENSES) OR ANY OTHER LIABILITY ARISING FROM, RELATED TO OR
 IN CONNECTION WITH YOUR ASSUMPTIONS OF LIABILITY.
If the disclaimer of warranty and limitation of liability provided
above cannot be given local legal effect according to their terms,
reviewing courts shall apply local law that most closely approximates
an absolute waiver of all civil liability in connection with the
Program, unless a warranty or assumption of liability accompanies a
copy of the Program in return for a fee.
"

version="0.0.1"
me="${0##*/}"
all_args="${*}"
start_time="$(date +%s)"

## colors
nocolor="\033[0m"
bold="\033[1m"
#nobold="\033[22m"
underline="\033[4m"
nounderline="\033[24m"
red="\033[31m"
green="\033[32m"
yellow="\033[33m"
blue="\033[34m"
magenta="\033[35m"
cyan="\033[36m"

## https://www.whonix.org/wiki/Main/Project_Signing_Key#cite_note-7
adrelanos_signify="untrusted comment: Patrick Schleizer adrelanos@whonix.org signify public key
RWQ6KRormNEETq+M8IysxRe/HAWlqZRlO8u7ACIiv5poAW0ztsirOjCQ"
## https://www.whonix.org/wiki/KVM/Project_Signing_Key#cite_note-4
hulahoop_signify="untrusted comment: signify public key
RWT2GZDQkp1NtTAC1IoQHUsyb/AQ2LIQF82cygQU+riOpPWSq730A/rq"
########################
## END DEFAULT VALUES ##
########################

################
## BEGIN MISC ##
################
## This is just a simple wrapper around 'command -v' to avoid
## spamming '>/dev/null' throughout this function. This also guards
## against aliases and functions.
## https://github.com/dylanaraps/pfetch/blob/pfetch#L53
has(){ _cmd="$(command -v "${1}")" 2>/dev/null || return 1
  [ -x "${_cmd}" ] || return 1
}


not_as_root(){
  [ "$(id -u)" -eq 0 ] && die 1 "Running as root, aborting."
}


## wrapper that supports su, sudo, doas
root_cmd(){
  test -z "${1:-}" && die 1 "Failed to pass arguments to root_cmd."
  if test -n "${sucmd_quote:-}"; then
    true "sucmd_quote"
    ${sucmd} '${@}'
  else
    ${sucmd} "${@}"
  fi
}


## check if variable is integer
is_integer(){
  printf %d "${1}" >/dev/null 2>&1 || return 1
}


## checks if the target is valid.
## Address range from 0.0.0.0 to 255.255.255.255. Port ranges from 0 to 65535
## this is not perfect but it is better than nothing
is_addr_port(){
  addr_port="${1}"
  port="${addr_port##*:}"
  addr="${addr_port%%:*}"

  is_integer "${port}" ||
    die 1 "Invalid port '${port}', not an integer."

  if [ "${port}" -gt 0 ] && [ "${port}" -le 65535 ]; then
    true "Valid port '${port}'"
  else
    die 1 "Invalid port '${port}', not within range: 0-65535."
  fi

  for quad in $(printf '%s\n' "${addr}" | tr "." " "); do
    is_integer "${quad}" ||
      die 1 "Invalid address '${addr}', '${quad}' is not an integer."
    if [ "${quad}" -ge 0 ] && [ "${quad}" -le 255 ]; then
      true "Valid quad '${quad}'"
    else
      die 1 "Invalid address '${addr}', '${quad}' not within range: 0-255."
    fi
  done
}


get_os(){
  ## Source: pfetch: https://github.com/dylanaraps/pfetch/blob/master/pfetch
  os="$(uname -s)"
  kernel="$(uname -r)"
  arch="$(uname -m)"

  case ${os} in
    Linux*)
      if test -f /usr/share/kicksecure/marker; then
        distro="Kicksecure"
        distro_version=$(cat /etc/kicksecure_version)
      elif test -f /usr/share/whonix/marker; then
        distro="Whonix"
        distro_version=$(cat /etc/whonix_version)
      elif has lsb_release; then
        distro=$(lsb_release -sd)
        distro_version=$(lsb_release -sc)
      elif test -f /etc/os-release; then
        while IFS='=' read -r key val; do
          case "${key}" in
            (PRETTY_NAME) distro=${val}
              ;;
            (VERSION_ID) distro_version=${val}
              ;;
          esac
        done < /etc/os-release
      else
        has crux && distro=$(crux)
        has guix && distro='Guix System'
      fi
      distro=${distro##[\"\']}
      distro=${distro%%[\"\']}
      case ${PATH} in (*/bedrock/cross/*) distro='Bedrock Linux' ;; esac
      if [ "${WSLENV:-}" ]; then
        distro="${distro}${WSLENV+ on Windows 10 [WSL2]}"
      elif [ -z "${kernel%%*-Microsoft}" ]; then
        distro="${distro} on Windows 10 [WSL1]"
      fi
    ;;
    Haiku) distro=$(uname -sv);;
    Minix|DragonFly) distro="${os} ${kernel}";;
    SunOS) IFS='(' read -r distro _ < /etc/release;;
    OpenBSD*) distro="$(uname -sr)";;
    FreeBSD) distro="${os} $(freebsd-version)";;
    *) distro="${os} ${kernel}";;
  esac
  log notice "Detected system: ${distro} ${distro_version}."
  log notice "Detected CPU arhictecture: ${arch}."
}

##############
## END MISC ##
##############

##########################
## BEGIN OPTION PARSING ##
##########################
## function should be called before the case statement to assign the options
## to a temporary variable
begin_optparse(){
  ## options ended
  test -z "${1:-}" && return 1
  shift_n=""
  ## save opt orig for error message to understand which opt failed
  opt_orig="${1}"
  # shellcheck disable=SC2034
  ## need to pass the second positional parameter cause maybe it is an argument
  arg_possible="${2}"
  clean_opt "${1}" || return 1
}


## if option requires argument, check if it was provided, if true, assign the
## arg to the opt. If $arg was already assigned, and if valid, will use it for
## the key value
## usage: get_arg key
get_arg(){
  ## if argument is empty or starts with '-', fail as it possibly is an option
  case "${arg:-}" in
    ""|-*)
      die 1 "Option '${opt_orig}' requires an argument."
      ;;
  esac
  set_arg "${1}" "${arg}"

  ## shift positional argument two times, as this option demands argument,
  ## unless they are separated by equal sign '='
  ## shift_n default value was assigned when trimming hifens '--' from the
  ## options. If shift_n is equal to zero, '--option arg', if shift_n is not
  ## equal to zero, '--option=arg'
  [ -z "${shift_n}" ] && shift_n=2
}


## single source to set opts, can later be used to print the options parsed
set_arg(){
  ## check if $var had already a value assigned
  eval var='$'"${1:-}"

  ## Escaping quotes is needed because else it fails if the argument is quoted
  # shellcheck disable=SC2140
  eval "${1}"="\"${2}\""

  ## variable used for --getopt
  if test -z "${arg_saved:-}"; then
    arg_saved="${1}=\"${2}\""
  else
    if test -z "${var}"; then
      arg_saved="${arg_saved}\n${1}=\"${2}\""
    else
      arg_saved="${arg_saved}\n${1}=\"${2}\""
      arg_saved="$(printf '%s\n' "${arg_saved}" | sed "s/${1}=.*/${1}=\"${2}\"/")"
    fi
  fi
}


## '--option=value' should shift once and '--option value' should shift twice
## but at this point it is not possible to be sure if option requires an
## argument, reset shift to zero, at the end, if it is still 0, it will be
## assigned to one, has to be zero here so we can check later if option
## argument is separated by space ' ' or equal sign '='
clean_opt(){
  case "${opt_orig}" in
    --)
      ## stop option parsing
      shift 1
      return 1
      ;;
    --*=*)
      ## long option '--sleep=1'
      opt="${opt_orig%=*}"
      opt="${opt#*--}"
      arg="${opt_orig#*=}"
      shift_n=1
      ;;
    -*=*)
      ## short option '-s=1'
      opt="${opt_orig%=*}"
      opt="${opt#*-}"
      arg="${opt_orig#*=}"
      shift_n=1
      ;;
    --*)
      ## long option '--sleep 1'
      opt="${opt_orig#*--}"
      arg="${arg_possible}"
      ;;
    -*)
      ## short option '-s 1'
      opt="${opt_orig#*-}"
      arg="${arg_possible}"
      ;;
    "")
      ## options ended
      return 1
      ;;
    *)
      ## not an option
      usage
      ;;
  esac
}


## check if argument is within range
## usage:
## $ range_arg key "1" "2" "3" "4" "5"
## $ range_arg key "a" "b" "c" "A" "B" "C"
range_arg(){
  key="${1:-}"
  eval var='$'"${key}"
  shift 1
  list="${*:-}"
  #range="${list#"${1} "}"
  if [ -n "${var:-}" ]; then
    success=0
    for tests in ${list:-}; do
      ## only envaluate if matches all chars
      [ "${var:-}" = "${tests}" ] && success=1 && break
    done
    ## if not within range, fail and show the fixed range that can be used
    if [ ${success} -eq 0 ]; then
      die 1 "Option '${key}' can not be '${var:-}'. Possible values: '${list}'."
    fi
  fi
}


## check if option has value, if not, error out
## this is intended to be used with required options
check_opt_filled(){
  key="${1}"
  eval val='$'"${key:-}"
  ! test -n "${val}" && die 1 "${key} is missing."
}
########################
## END OPTION PARSING ##
########################

###################
## BEGIN LOGGING ##
###################
## usage: log [info|notice|warn|error] "X occurred."
log(){
  log_type="${1}"
  shift 1
  log_content="${*}"
  log_type_up="$(echo "${log_type}" | tr "[:lower:]" "[:upper:]")"
  case "${log_type}" in
    bug)
      log_color="${yellow}"
      ;;
    error)
      log_color="${red}"
      ;;
    warn)
      log_color="${magenta}"
      ;;
    info)
      log_color="${cyan}"
      ;;
    notice)
      log_color="${green}"
      ;;
  esac
  ## uniform log format
  log_color="${bold}${log_color}"
  log_full="${me}: [${log_color}${log_type_up}${nocolor}]: ${log_content}"
  ## error logs are the minimum and should alwasy be printed, even if
  ## failing to assign a correct log type
  ## send bugs and error to stdout and stderr
  case "${log_type}" in
    bug)
      printf %s"${log_full} Please report this bug.\n" 1>&2
      return 0
      ;;
    error)
      printf %s"${log_full}\n" 1>&2
      return 0
      ;;
  esac
  ## reverse importance order is required, excluding 'error'
  all_log_levels="warn notice info debug"
  if echo " ${all_log_levels} " | grep -o ".* ${log_level} " \
    | grep -q " ${log_type}"
  then
    case "${log_type}" in
      warn)
        ## send warning to stdout and stderr
        printf %s"${log_full}\n" 1>&2
        ;;
      *)
        printf %s"${log_full}\n"
        ;;
    esac
  fi
}


## 'log' should not handle exits, because then it would not be possible
## to log consecutive errors on multiple lines, making die more suitable
## for one liners 'log error; die'
## usage: die # "msg"
## where '#' is the exit code.
die(){
  log_elapsed_time
  log error "${2}"
  log error "Aborting installer."
  exit "${1}"
}


## wrapper to log command before running to avoid duplication of code
log_and_run(){
  log info "Running command: $ (${1})"
  ${1}
}


## useful to get runtime mid run to log easily
get_elapsed_time(){
  printf '%s\n' "$(($(date +%s) - start_time))"
}


log_elapsed_time(){
  log info "Elapsed time (seconds): $(get_elapsed_time)."
}


handle_exit(){
  last_exit="${1}"
  line_number="${2:-0}"
  ## return instead of exit because maybe this is not the last trap.
  test "${last_exit}" = "0" && return 0
  ## some shells have a bug that displays line 1 as LINENO
  if test "${line_number}" -gt 2; then
    log bug "At line: ${line_number}."
    pr -tn "${0}" | tail -n+$((line_number - 3)) | head -n7
  else
    log error "Exit code: ${last_exit}."
  fi
}


#################
## END LOGGING ##
#################

###########################
## BEGIN SCRIPT SPECIFIC ##
###########################
get_host_pkgs(){
  case "${os}" in
    Linux*)
      case "${distro}" in
        "Debian"*|"Linux Mint"*|"LinuxMint"*|"mint"*|"Tails"*)
          true "Debian"
          pkg_mngr="apt"
          pkg_mngr_install="${pkg_mngr} install --yes"
          pkg_mngr_update="${pkg_mngr} update --yes"
          pkg_mngr_check_installed="dpkg -s"
          install_virtualbox_debian
          install_signify signify-openbsd
          ;;
        *"buntu"*)
          true "Ubuntu"
          pkg_mngr="apt"
          pkg_mngr_install="${pkg_mngr} install --yes"
          pkg_mngr_update="${pkg_mngr} update --yes"
          pkg_mngr_check_installed="dpkg -s"
          install_virtualbox_ubuntu
          install_signify signify-openbsd
          if [ "$(echo "${distro_version}" | tr -d ".")" -lt 2204 ]; then
            die 1 "Minimal ${distro} required version is 22.04, yours is ${distro_version}."
          fi
          ;;
        "Kicksecure"|"Whonix")
          true "Kicksecure/Whonix"
          pkg_mngr="apt"
          pkg_mngr_install="${pkg_mngr} install --yes"
          pkg_mngr_update="${pkg_mngr} update --yes"
          pkg_mngr_check_installed="dpkg -s"
          install_virtualbox_kicksecure
          install_signify signify-openbsd
          ;;
        "Arch"*|"Artix"*|"ArcoLinux"*)
          die 1 "Unsupported system."
          ;;
        "Fedora"*|"CentOS"*|"rhel"*|"Redhat"*|"Red hat")
          die 1 "Unsupported system."
          ;;
        *)
          die 1 "Unsupported system."
          ;;
      esac
    ;;
    "OpenBSD"*)
      die 1 "Unsupported system."
      ;;
    "NetBSD"*)
      die 1 "Unsupported system."
      ;;
    "FreeBSD"*|"HardenedBSD"*|"DragonFly"*)
      die 1 "Unsupported system."
      ;;
    *)
      die 1 "Unsupported system."
      ;;
  esac
}


install_pkg(){
  pkgs="${@}"
  pkg_not_installed=""
  for pkg in ${pkgs}; do
    ${pkg_mngr_check_installed} "${pkg}" >/dev/null 2>&1 ||
      pkg_not_installed="${pkg_not_installed} ${pkg}"
  done

  if test -n "${pkg_not_installed}"; then
    log notice "Updating package list."
    root_cmd ${pkg_mngr_update}
    log notice "Installing package(s):${pkg_not_installed}."
    root_cmd ${pkg_mngr_install} ${pkg_not_installed}
    fi
}


test_pkg(){
  pkgs="${@}"
  pkg_not_installed=""
  for pkg in ${pkgs}; do
    ${pkg_mngr_check_installed} "${pkg}" >/dev/null 2>&1 ||
      pkg_not_installed="${pkg_not_installed} ${pkg}"
  done

  if ! test -n ${pkg_not_installed}; then
    die 1 "Failed to locate package(s):${pkg_not_installed}."
  fi
}


abort_on_existence(){
  ## testing if file exists, not minding if it is a refular file or not
  if test -e "${1:-}"; then
    log error "File exists: ${guest_basedir}/${guest_up}-${interface_up}.vbox."
    die 1 "Not touching user data, aborting."
  fi
}


common_virtualbox_install_end(){
  has vboxmanage || die 1 "Failed to locate 'vboxmanage' program."
  root_cmd adduser $(whoami) vboxusers || {
    die 1 "Failed to add user '$(whoami)' to group 'vboxusers'."
  }
}


install_virtualbox_debian(){
  has vboxmanage && return 0
  install_pkg fasttrack-archive-keyring
  test_pkg fasttrack-archive-keyring
  ## TODO: check if fasttrack is already enabled, apt gives error on dups
  echo 'deb https://fasttrack.debian.net/debian/ bullseye-fasttrack main contrib non-free' | root_cmd tee /etc/apt/sources.list.d/fasttrack.list >/dev/null
  install_pkg virtualbox linux-headers-$(dpkg --print-architecture)
  common_virtualbox_install_end
}


install_virtualbox_ubuntu(){
  has vboxmanage && return 0
  install_pkg virtualbox linux-headers-generic
  common_virtualbox_install_end
}


install_virtualbox_kicksecure(){
  has vboxmanage && return 0
  install_pkg virtualbox linux-headers-$(dpkg --print-architecture)
  common_virtualbox_install_end
}


install_signify(){
  if has signify-openbsd; then
    ## fix debian unconventional naming
    signify(){ signify-openbsd "${@}"; }
    return 0
  fi

  pkg_name="${1:-signify}"
  has "${pkg_name}" && return 0
  install_pkg "${pkg_name}"
  test_pkg "${pkg_name}"
}


check_license(){
  if [ "${non_interactive}" = "1" ]; then
    log notice "License agreed by the user by setting non_interactive option."
    return 0
  fi

  while true; do
    has dialog && dialog_box="dialog" && break
    has whiptail && dialog_box="whiptail" && break
    break
  done

  case "${dialog_box}" in
    dialog)
      dialog --erase-on-exit --no-shadow \
        --title "${dialog_title}" --defaultno \
        --yes-label "Understood" \
        --no-label "Not understood" \
        --yesno "${license}" \
        640 480
      ;;
    whiptail)
      whiptail --scrolltext --title "${dialog_title}" --defaultno \
        --yes-button "Understood" \
        --no-button "Not understood" \
        --yesno "${license}" \
        24 80
      ;;
    *)
      log notice "The license will be printed to screen, read with care."
      sleep 3
      printf '%s\n' "${license}"
      printf '%s' "Do you agree with the license(s)? (yes/no): "
      read -r license_agreement
      case "${license_agreement}" in
        [yY][eE][sS])
          true
          ;;
        *)
          log warn "User replied '${license_agreement}'."
          return 1
          ;;
      esac
      ;;
  esac
}


import_virtualbox(){
  vboxmanage import "${curl_opt_save_dir}/${guest_file}.${guest_file_ext}" \
    --vsys 0 --eula accept --vsys 1 --eula accept
}


import_kvm(){
  ## placeholder
  die 1 "KVM import not coded."
}

get_utilities(){
  while true; do
    has sha512sum && checkhash="sha512sum" && break
    has shasum && checkhash="shasum -a 512" && break
    has sha512 && checkhash="sha512" && break
    has openssl && checkhash="openssl dgst -sha512 -r" && break
    has digest && checkhash="digest -a sha512" && break
    test -z "${checkhash}" && {
      die 1 "Failed to find program that checks SHA512 hash sum."
    }
  done

  while true; do
    has sudo && sucmd=sudo && break
    has doas && sucmd=doas && break
    has su && sucmd="su -c" && sucmd_quote=1 && break
    test -z "${sucmd}" && {
      die 1 "Failed to find program to run as another user."
    }
  done
  root_cmd echo hello >/dev/null || {
    die 1 "Failed to run test command as root."
  }
}

set_trap(){
  ## Get current shell from current process
  ## If the process if the file name, get its shell from shebang
  curr_shell="$(ps | awk "/ $$ /" | awk '{print $4}')"
  ## sometimes the process name is the base name of the script with some
  ## missing letters.
  if [ ${curr_shell}* = "${0##*/}" ]; then
    shebang="$(head -1 $0)"
    curr_shell="${shebang##*/}"
  fi
  case "${curr_shell}" in
    *bash|*ksh|*zsh)
      test "${curr_shell}" = "bash" && set -o errtrace
      trap 'handle_exit $? ${LINENO:-}' ERR
      ;;
  esac
  ## every script exit should be handled by this trap
  trap 'handle_exit $? ${LINENO:-}' EXIT
}



## sanity checks that should be called before execution of main
pre_check(){
  set_trap
  get_os
  get_utilities
  check_virtualization
  get_host_pkgs

  if [ "${arch}" != "x86_64" ]; then
    die 1 "Only supported architecture is x86_64, your's is ${arch}."
  fi

  ## min_ram_mb not used currently because less than total 4GB is too low
  ## already
  ## https://www.whonix.org/wiki/RAM#Whonix_RAM_and_VRAM_Defaults
  case "${interface}" in
    xfce)
      min_ram_mb="3328"
      ;;
    cli)
      min_ram_mb="1024"
      ;;
  esac

  ## 4GB RAM machine reports 3844Mi and 4031MB
  total_mem="$(free --mega | awk '/Mem:/{print $2}')"
  ## capped to 4200MB to report that 4GB RAM on the host is too little
  if [ "${total_mem}" -lt "4200" ]; then
    log warn "Your systems has a low amount of total RAM: ${total_mem}."
    log warn "You may encounter problems using a desktop environment."
  fi

  free_space="$(df --output=avail -BG . | awk '/G$/{print substr($1, 1, length($1)-1)}')"
  if [ ${free_space} -lt 10 ]; then
    die 1 "You need at least 10G of available space, you only have ${free_space}G."
  fi

  has curl || install_pkg curl
  test_pkg curl
}


## used for SOCKS credentials and stream isolation with
## curl [-U|--proxy-user] user:password
posix_rand(){
  awk \
  'BEGIN {
    srand();
    chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    s = "";
    for(i=0;i<8;i++) {
        s = s "" substr(chars, int(rand()*62), 1);
    }
    print s
  }'
}


## generate SOCKS credentials for stream isolation
## use script name as the user for easier filtering of the controller logs
get_curl_proxy_cred(){
  test "${distro:-}" = "Whonix" && return 0
  test "${onion:-}" != "1" && return 0
  proxy_user="anonym"
  proxy_pass="$(posix_rand)"
  printf '%s' "-U ${proxy_user}:${proxy_pass}"
}


check_tor_proxy(){
  log notice "Testing SOCKS proxy: ${proxy}."
  curl_reply="$(curl -sSI -m 3 "${proxy}" | head -1 | tr -d "\r")"
  expected_curl_reply="HTTP/1.0 501 Tor is not an HTTP Proxy"
  if [ "${curl_reply}" = "${expected_curl_reply}" ]; then
    log notice "Connected to tor SOCKS proxy succesfully."
    log info "${curl_reply}."
    return 0
  else
    log error "Unexpected proxy response (maybe not a tor proxy?)."
    log error "${curl_reply}."
    return 1
  fi

}

## useful to test if it is a SOCKS proxy before attempting to connect
## to onion hosts.
torify_conn(){
  if test "${distro:-}" = "Whonix"; then
    log info "Skipping torifying connection because of distro: ${distro}."
    return 0
  fi
  ## curl does not support SOCKS proxy to connect with Unix Domain Socket
  ##  https://curl.se/mail/archive-2021-03/0013.html
  if test -n "${socks_proxy:-}"; then
    proxy="${socks_proxy}"
    curl_proxy="-x socks5h://${proxy}"
  elif test -n "${TOR_SOCKS_PORT:-}"; then
    proxy="${TOR_SOCKS_HOST:-127.0.0.1}:${TOR_SOCKS_PORT}"
    curl_proxy="-x socks5h://${proxy}"
  else
    log warn "Missing SOCKS proxy for torified connections."
    log warn "Trying tor defaults: TBB (9150) and system tor (9050)."
    proxy="127.0.0.1:9050"
    curl_proxy="-x socks5h://${proxy}"
    if ! check_tor_proxy; then
      proxy="127.0.0.1:9050"
      curl_proxy="-x socks5h://${proxy}"
    else
      return 0
    fi
  fi
  check_tor_proxy || die 1 "SOCKS proxy not setup correctly."
}


## set version by user input or by querying the API
get_version(){
  if test -n "${guest_version_user:-}"; then
    log info "User input version."
    guest_version="${guest_version_user}"
    return 0
  fi
  log info "Acquiring guest version from API."
  log info "API host: ${1}."
  raw_version="$(curl ${curl_proxy:-} $(get_curl_proxy_cred) ${curl_opt_ssl:-} "${1}")"
  guest_version="$(printf '%s\n' "${raw_version}" | sed "s/<.*//")"
}


download_files(){
  download_dir="${1:?}"
  download_flag="${download_dir}/${guest_file}.${guest_file_ext}.flag"
  if test -f "${download_flag}"; then
    log notice "Skipping download because flag exists: ${download_flag}."
    return 0
  fi

  log_elapsed_time
  curl_full_download="curl --fail-early --fail --show-error --location --create-dirs --output-dir ${download_dir} ${curl_opt_ssl:-} ${curl_proxy:-} $(get_curl_proxy_cred) --remote-name "

  log notice "Downloading ${guest_file}.${guest_file_ext}."
  log_and_run "${curl_full_download} ${url_guest_file}.${guest_file_ext}" ||
    return 1

  log notice "Downloading ${guest_file}.sha512sums.sig."
  log_and_run "${curl_full_download} ${url_guest_file}.sha512sums.sig" ||
    return 1

  log notice "Downloading ${guest_file}.sha512sums."
  log_and_run "${curl_full_download} ${url_guest_file}.sha512sums" ||
    return 1

  log_elapsed_time
  touch "${download_flag}"
  return 0
}


## https://en.wikipedia.org/wiki/X86_virtualization
check_virtualization(){
  ## check cpu flags for capability
  virt_flag="$(root_cmd grep -m1 -w '^flags[[:blank:]]*:' /proc/cpuinfo | grep -wo -E '(vmx|svm)' || true)"

  case "${virt_flag:=}" in
    vmx) brand=intel;;
    svm) brand=amd;;
  esac

#  if compgen -G "/sys/kernel/iommu_groups/*/devices/*" > /dev/null; then
#    log notice "${brand}'s I/O Virtualization Technology is enabled in the BIOS/UEFI"
#  else
#    log warn "${brand}'s I/O Virtualization Technology is not enabled in the BIOS/UEFI"
#  fi

  case "${virt_flag:=}" in
    vmx|svm)
      log notice "Your CPU supports virtualization: ${brand}: ${virt_flag}."
      return 0
      ;;
    "")
      log warn "Virtualization not available, could be either:"
      log warn "  a) not enabled in your BIOS; or"
      log warn "  b) not available for your CPU."
      return 1
      ;;
    *)
      log warn "Unknown virtualization flag: ${virt_flag}."
      log warn "  Please report this bug."
      return 1
      ;;
  esac


  ## msr is blocked by security-misc. If no other solution is found,
  ## remove the rest of of this function.
  ## $ modprobe msr
  ## /bin/disabled-msr-by-security-misc: ERROR: This CPU MSR kernel module is disabled by package security-misc by default. See the configuration file /etc/modprobe.d/30_security-misc.conf | args:
  ## modprobe: ERROR: ../libkmod/libkmod-module.c:990 command_do() Error running install command '/bin/disabled-msr-by-security-misc' for module msr: retcode 1
  ## modprobe: ERROR: could not insert 'msr': Invalid argument

  install_pkg msr-tools
  test_pkg msr-tools
  # https://bazaar.launchpad.net/~cpu-checker-dev/cpu-checker/trunk/view/head:/kvm-ok
  # kvm-ok - check whether the CPU we're running on supports KVM acceleration
  # Copyright (C) 2008-2010 Canonical Ltd.
  #
  # Authors:
  #  Dustin Kirkland <kirkland@canonical.com>
  #  Kees Cook <kees.cook@canonical.com>
  #
  # This program is free software: you can redistribute it and/or modify
  # it under the terms of the GNU General Public License version 3,
  # as published by the Free Software Foundation.
  #
  # This program is distributed in the hope that it will be useful,
  # but WITHOUT ANY WARRANTY; without even the implied warranty of
  # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  # GNU General Public License for more details.
  #
  # You should have received a copy of the GNU General Public License
  # along with this program.  If not, see <http://www.gnu.org/licenses/>.

  ## Print verdict
  verdict() {
    case "${1}" in
      0)
        log notice "Virtualization can be used."
        return 0
        ;;
      1)
        die 1 "Virtualization can NOT be used."
        ;;
      2)
        log warn "Virtualization can be used, but not enabled."
        return 1
        ;;
    esac
  }

  ## Check cpu flags for capability
  virt=$(root_cmd grep -m1 -w '^flags[[:blank:]]*:' /proc/cpuinfo |
         grep -wo -E '(vmx|svm)')
  if test -z "${virt}"; then
    log error "Your CPU does not support Virtualization."
    verdict 1
  fi
  [ "${virt}" = "vmx" ] && brand="intel"
  [ "${virt}" = "svm" ] && brand="amd"

  # Now, check that the device exists
# if test -e /dev/kvm; then
#   echo "INFO: /dev/kvm exists"
#   verdict 0
# else
#   echo "INFO: /dev/kvm does not exist"
#   echo "HINT:   sudo modprobe kvm_$brand"
# fi

  ## Prepare MSR access
  msr="/dev/cpu/0/msr"
  root_cmd test ! -r "${msr}" && root_cmd modprobe msr
  if root_cmd test ! -r "${msr}"; then
    log error "Cannot read ${msr}"
    return 1
  fi

  log notice "Your CPU supports Virutalization extensions."

  virt_disabled=0
  ## check brand-specific registers
  if [ "${virt}" = "vmx" ]; then
    virt_bit=$(root_cmd rdmsr --bitfield 0:0 0x3a 2>/dev/null || true)
    if [ "${virt_bit}" = "1" ]; then
      ## and FEATURE_CONTROL_VMXON_ENABLED_OUTSIDE_SMX clear (no tboot)
      virt_bit=$(root_cmd rdmsr --bitfield 2:2 0x3a 2>/dev/null || true)
      [ "${virt_bit}" = "0" ] && virt_disabled=1
    fi
  elif [ "${virt}" = "svm" ]; then
    virt_bit=$(root_cmd rdmsr --bitfield 4:4 0xc0010114 2>/dev/null || true)
    [ "${virt_bit}" = "1" ] && virt_disabled=1
  else
    log error "Unknown virtualization extension: ${virt}"
    verdict 1
  fi

  if [ "${virt_disabled}" -eq 1 ]; then
    log warn "'${virt}' is disabled by your BIOS"
    log warn "Enter your BIOS setup and enable Virtualization Technology (VT),"
    log warn "      and then reboot your system."
    verdict 2
  fi

  verdict 0
}

## set default values of variables
set_default(){
  : "${arg_saved:=""}"
  : "${guest:="whonix"}"
  : "${hypervisor:="virtualbox"}"
  : "${interface:="xfce"}"
  : "${log_level:="notice"}"
  : "${socks_proxy:=""}"
  : "${onion:=""}"
  : "${non_interactive:=""}"
  : "${dev:=""}"
}

#########################
## END SCRIPT SPECIFIC ##
#########################

################
## BEGIN MAIN ##
################
usage(){
  printf %s"Usage: ${me} [options...]
 -g, --guest         Set guest. Options: kicksecure, whonix (default)
 -u, --guest-version <version>
                     Set guest version, else query from API.
 -i, --interface <interface>
                     Set interface. Options: cli, xfce (default)
 -m, --hypervisor <platform>
                     Set virtualization. Options: kvm, virtualbox (default)
 -o, --onion         Download files over onion.
 -s, --socks-proxy <proxy>
                     Set TCP SOCKS proxy for onion client connections.
                       (default: TOR_SOCKS_HOST:TOR_SOCKS_PORT, if not set, try
                       TBB proxy at 9150, else try system tor proxy at 9050)
 -l, --log-level <level>
                     Set log level. Options: debug, info,
                       notice (default), warn, error.
 -n, --non-interactive
                     Set non-interactive mode, license will be accepted.
 -t, --getopt        Get parsed options and exit.
 -V, --version       Print script version.
 -h, --help          Print this help message.
"
  exit 1
}


#test -z "${1:-}" && usage
set_default
while true; do
  begin_optparse "${1:-}" "${2:-}" || break
  # shellcheck disable=SC2034
  case "${opt}" in
    o|onion)
      set_arg onion 1
      ;;
    s|socks-proxy)
      get_arg socks_proxy
      ;;
    l|log-level)
      get_arg log_level
      ;;
    g|guest)
      get_arg guest
      ;;
    u|guest-version)
      get_arg guest_version_user
      ;;
    i|interface)
      get_arg interface
      ;;
    m|hypervisor)
      get_arg hypervisor
      ;;
    n|non-interactive)
      set_arg non_interactive 1
      ;;
    t|getopt)
      set_arg dev getopt
      ;;
    V|version)
      set_arg dev version
      ;;
    h|help)
      usage
      ;;
    *)
      die 1 "Invalid option: '${opt_orig}'."
      ;;
  esac
  shift "${shift_n:-1}"
done


range_arg guest whonix kicksecure
range_arg hypervisor kvm virtualbox
range_arg interface cli xfce
range_arg log_level error warn notice info debug
[ "${log_level}" = "debug" ] && set -o xtrace


case "${dev:-}" in
  getopt)
    printf %s"${arg_saved}\n"
    exit 0
    ;;
  version)
    printf '%s\n' "${me} ${version}"
    exit 0
    ;;
esac


check_license || die 1 "User disagreed with the license."
log notice "User agreed with the license."
log info "Command line options: ${all_args}."

pre_check
log_elapsed_time

log notice "Virtualization: ${hypervisor}."
log notice "Guest: ${guest}."
log notice "Interface: ${interface}."
interface_up="$(echo "${interface}" | tr "[:lower:]" "[:upper:]")"


case "${guest}" in
  whonix)
    site_onion="dds6qkxpwdeubwucdiaord2xgbbeyds25rbsgr73tbfpqpt4a6vjwsyd.onion"
    site="whonix.org"
    site_dl="mirrors.dotsrc.org/${guest}"
    ;;
  kicksecure)
    site_onion="w5j6stm77zs6652pgsij4awcjeel3eco7kvipheu6mtr623eyyehj4yd.onion"
    site="kicksecure.com"
    #site_download="dotsrccccbidkzg7oc7oj4ugxrlfbt64qebyunxbrgqhxiwj3nl6vcad.onion/${guest}"
    site_dl="dds6qkxpwdeubwucdiaord2xgbbeyds25rbsgr73tbfpqpt4a6vjwsyd.onion"
    ;;
esac
##
site_mirror="mirrors.dotsrc.org/${guest}"

guest_up="$(echo "${guest}" | awk '{$1=toupper(substr($1,0,1))substr($1,2)}1')"


case "${onion}" in
  1)
    log info "Onion preferred."
    torify_conn
    curl_opt_ssl=""
    url_origin="http://www.${site_onion}"
    url_download="http://download.${site_onion}"
    #url_download="http://${site_dl}"
    url_version="w/index.php?title=Template:VersionNew&stable=0&action=raw"
    url_version="http://www.${site_onion}/${url_version}"
    ;;
  *)
    log info "Clearnet preferred."
    test -n "${socks_proxy}" && torify_conn
    curl_opt_ssl="--tlsv1.3 --proto =https"
    url_origin="https://www.${site}"
    url_download="https://${site_dl}"
    #url_download="https://download.${site}"
    url_version="w/index.php?title=Template:VersionNew&stable=0&action=raw"
    url_version="https://www.${site}/${url_version}"
    ;;
esac


case "${hypervisor}" in
  virtualbox)
    signify_key="${adrelanos_signify}"
    url_domain="${url_download}/ova"
    guest_file_ext="ova"
    guest_version="w/index.php?title=Template:VersionNew&stable=0&action=raw"
    import_guest="import_virtualbox"
    guest_basedir="${HOME}/VirtualBox VMs"
    case "${guest}" in
      whonix)
        previous_import="${guest_basedir}/${guest_up}-Workstation-${interface_up}.vbox ${guest_basedir}/${guest_up}-Gateway-${interface_up}.vbox"
        ;;
      kicksecure)
        previous_import="${guest_basedir}/${guest_up}-${interface_up}.vbox"
        ;;
    esac
    ;;

  kvm)
    signify_key="${hulahoop_signify}"
    url_domain="${url_download}/libvirt"
    guest_file_ext="Intel_AMD64.qcow2.libvirt.xz"
    guest_version="w/index.php?title=Template:Version_KVM&stable=0&action=raw"
    import_guest="import_kvm"
    ## TODO
    die 1 "KVM code is unfinished."
    #guest_basedir="${HOME}/VirtualBox VMs"
    #abort_on_existence "kvmfile"
    ;;
esac

for vm in ${previous_import}; do
  abort_on_existence "${vm}"
done

curl -sSf -m 20 --fail-early "${url_download}" >/dev/null ||
  die 1 "Can't connect to destination, perhaps you don't have internet?"

get_version "${url_origin}/${guest_version}."
log notice "Version: ${guest_version}."

url_domain="${url_domain}/${guest_version:?}"
guest_file="${guest_up}-${interface_up}-${guest_version}"
url_guest_file="${url_domain}/${guest_file}"
curl_opt_save_dir="${HOME}/dist-installer"

download_files "${curl_opt_save_dir}" || die 1 "Failed to download files."

log notice "Signify signature:\n${signify_key}"
log notice "Verifying file: ${curl_opt_save_dir}/${guest_file}.sha512sums."
echo "${signify_key}" | signify -V -p - \
 -m "${curl_opt_save_dir}/${guest_file}.sha512sums" ||
  die 1 "Failed to verify signature."

log notice "Checking SHA512 checksum: ${curl_opt_save_dir}/${guest_file}.${guest_file_ext}"
${checkhash} "${curl_opt_save_dir}/${guest_file}.sha512sums" ||
  die 1 "Failed hash checking."

log_elapsed_time
${import_guest}

log_elapsed_time
