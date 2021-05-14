#!/bin/bash

set -eu
 
APP="Libvirt Network Hook"
DNSMASQ_CONFIG=${DNSMASQ_CONFIG:-/etc/dnsmasq.d/libvirt-hook.conf}

net_stopped ()
{
    local net_name=${1}
    local action=$2
    local order=$3
    local stdin=$4

    logger -s "$APP: Removing dnsmasq hooks for $net_name"

    # Fetch stdin config
    if [[ "$stdin" == "-" ]]; then
        stdin=$(cat - )
    else
        logger -s "$APP: No stdin configuration found."
    fi
    
    # Extract network data
    net_domain=$(xmlstarlet sel -t -m '//hookData/network/domain'  -v "@name" <<< "$stdin" 2>/dev/null || true )
    net_ip=$(xmlstarlet sel -t -m '//hookData/network/ip'  -v "@address" <<< "$stdin" 2>/dev/null || true )
    if [[ -z "$net_domain" ]]; then
        logger -s "$APP: Missing domain."
        return
    elif [[ -z "$net_ip" ]]; then
        logger -s "$APP: Missing IP."
        return
    fi

    # Update dnsmasq config
    logger -s "$APP: Adding dnsmasq config for: $net_domain => $net_ip"
    dns_conf="server=/$net_domain/$net_ip#53"
    if grep -q "^server=/$net_domain/" "$DNSMASQ_CONFIG"; then
        sed -i "/^server=\/$net_domain\/.*/d" "$DNSMASQ_CONFIG"
        logger -s "$APP: dnsmasq configuration has been removed"

        # Reload dnsmasq
        systemctl reload dnsmasq
        logger -s "$APP: Network '$net_name' hook succesfully executed"
    else
        logger -s "$APP: dnsmasq configuration was already up to date: $DNSMASQ_CONFIG"
    fi

}

net_started ()
{
    local net_name=${1}
    local action=$2
    local order=$3
    local stdin=$4

    logger -s "$APP: Adding dnsmasq hooks for $net_name"

    # Fetch stdin config
    if [[ "$stdin" == "-" ]]; then
        stdin=$(cat - )
    else
        logger -s "$APP: No stdin configuration found."
    fi
    
    # Extract network data
    net_domain=$(xmlstarlet sel -t -m '//hookData/network/domain'  -v "@name" <<< "$stdin" 2>/dev/null || true )
    net_ip=$(xmlstarlet sel -t -m '//hookData/network/ip'  -v "@address" <<< "$stdin" 2>/dev/null || true )
    if [[ -z "$net_domain" ]]; then
        logger -s "$APP: Missing domain."
        return
    elif [[ -z "$net_ip" ]]; then
        logger -s "$APP: Missing IP."
        return
    fi

    # Update dnsmasq config
    logger -s "$APP: Adding dnsmasq config for: $net_domain => $net_ip"
    dns_conf="server=/$net_domain/$net_ip#53"
    if grep -q "^server=/$net_domain/" "$DNSMASQ_CONFIG"; then
        sed -i "s@^server=/$net_domain/@$dns_conf@" "$DNSMASQ_CONFIG"
    else
        echo "$dns_conf" >> "$DNSMASQ_CONFIG"
    fi

    # Reload dnsmasq
    systemctl reload dnsmasq
    logger -s "$APP: Network '$net_name' hook succesfully executed"
}


main ()
{
    local net_name=${1}
    local action=$2

    script="${BASH_SOURCE[0]}"
    event=${script##*/}
    logger -s "$APP: Source: $script"

    [ -f "$DNSMASQ_CONFIG" ] || echo "# Managed by $0" > "$DNSMASQ_CONFIG"

    case "$action" in
        started)
            net_started $@
            ;;
        stopped)
            net_stopped $@
            ;;
        *)
            logger -s "$APP: No action ($action) for $net_name"
            ;;
    esac
}


main $@
