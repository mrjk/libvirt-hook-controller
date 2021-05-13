#!/bin/bash
#
# Libvirt Hook Controller
# =========================
# Little tool to manage libivrt hooks in an easy way. Supp
#
# Author: mrjk
# License: MIT
# Date: 05/2021


set -eu

HOOKS="
/etc/libvirt/hooks/daemon
/etc/libvirt/hooks/qemu
/etc/libvirt/hooks/lxc
/etc/libvirt/hooks/libxl
/etc/libvirt/hooks/network
"
APP_NAME="libvirt-hooks"
APP_CONF_DIR=/etc/libvirt/hooks/conf
FAIL_ON_ERROR=false

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

#    logger -s  "Config:
#$config"

    # Execute commands
    while read cmd; do
        logger -s "$APP_NAME: Execute: $cmd $@"

        # Execute command
        set +e
        local rc=0
        if [[ "$args" == '-' ]]; then
            printf "%s" "$stdin" | $cmd $@
        else
            $cmd $@
        fi
        rc=$?
        set -e

        # Check result
        if [[ "$rc" -ne 0 ]]; then
            if $FAIL_ON_ERROR; then
                logger -s "$APP_NAME: An error occured, got return code: $rc"
                exit $rc
            else
                logger -s "$APP_NAME: Ignoring non-zero return code: $rc"
            fi
        fi

    done <<< "$config"

}


main $@
