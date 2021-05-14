#!/bin/bash
#
# Libvirt Hook Controller
# =========================
# Little tool to manage libivrt hooks in an easy way.
# 
# Documentation:
# ---------------
# - https://libvirt.org/hooks.html
#
#
# Installation:
# ---------------
# You just have to symlink libvirt hooks to this script. In bash, you can install it this way:
#   for i in /etc/libvirt/hooks/{daemon,libxl,lxc,network,qemu} ; do ln -s $PWD/libvirt_hook_controller.sh $i ; done
# Then check your journalctl to see hooks events.
#
#
# Usage:
# ---------------
# Libvirt Hook Controller works with one or more configuration files. By default
# it looks into the file `rules.conf` and `rules.d/*.conf` in `/etc/libvirt/hooks/conf`.
# The configuration files are basically a csv file with some fields:
#   - hook: The name of the hook to match. Can use '*'.
#   - operation: The name of the operation to match. Can use '*'.
#   - object: A name of object to filter. Recommanded to use '*'.
#   - priority: A number between 0 and 99. Can use '*' to be set to 50.
#   - command: Command to execute.
#
#
# Configuration examples:
# ---------------
#     network;started;*;*;/usr/local/update_dns hook add
#     network;stopped;*;5;/usr/local/update_dns hook remove
#     network;stopped;*;10;/usr/local/update_dns hook remove
#     network;stopped;*;4;/usr/local/update_dns hook remove
#     network;stopped;*;60;/usr/local/update_dns hook remove
#     qemu;started;*;*;/usr/local/bin/ensure_ipvsadm
#     *;*;*;99;/usr/anyevent
#
#
# Infos:
# ---------------
#   Author: mrjk
#   License: MIT
#   Date: 05/2021
#   Version: 1.0
#
#
# EOFDOC

set -eu

APP_HOOKS="
/etc/libvirt/hooks/daemon
/etc/libvirt/hooks/qemu
/etc/libvirt/hooks/lxc
/etc/libvirt/hooks/libxl
/etc/libvirt/hooks/network
"
APP_NAME="libvirt_hook_controller"
APP_CONF_DIR=${APP_CONF_DIR:-/etc/libvirt/hooks/conf}
APP_FAIL_ON_ERROR=${APP_FAIL_ON_ERROR:-false}

main ()
{
    local object=${1}
    local operation=${2}
    local sub=${3}
    local args=${4}

    # Capture stdin
    local stdin=
    if [[ "$args" == '-' ]]; then
        stdin=$(cat -)
    fi

    # Guess the hook name from symlink file
    local script="${BASH_SOURCE[0]}"
    local hook=${script##*/}

    logger -s "$APP_NAME: Hook: $operation $hook for $object"

    # Assemble config
    local config=$(cat "$APP_CONF_DIR/rules.conf" "$APP_CONF_DIR/rules.d"/*.conf 2>/dev/null)
    config=$(grep -E "^(($hook)|(\*));" <<< "$config" | sort | uniq | cut -f2- -d";")
    config=$(grep -E "^(($operation)|(\*));" <<< "$config" | sort | uniq | cut -f2- -d";")
    config=$(grep -E "^(($object)|(\*));" <<< "$config" | sort | uniq | cut -f2- -d";")
    config=$(sed 's/^\*;/50;/' <<< "$config" | sort -h -k1,1 -k2,2 -t";" )
    config=$( cut -f2- -d";"  <<< "$config")

    # logger -s  "Config: $config"

    # Execute commands
    while read cmd; do

        # Execute command
        set +e
        local rc=0
        if [[ "$args" == '-' ]]; then
            logger -s "$APP_NAME: Execute with stdin data: $cmd $@"
            printf "%s" "$stdin" | $cmd $@
        else
            logger -s "$APP_NAME: Execute: $cmd $@"
            $cmd $@
        fi
        rc=$?
        set -e

        # Log or fail on errors
        if [[ "$rc" -ne 0 ]]; then
            if $APP_FAIL_ON_ERROR; then
                logger -s "$APP_NAME: An error occured, got return code: $rc"
                exit $rc
            else
                logger -s "$APP_NAME: Ignoring non-zero return code: $rc"
            fi
        fi
    done <<< "$config"
}

main $@
