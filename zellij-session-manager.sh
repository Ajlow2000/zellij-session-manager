#!/usr/bin/env bash

if [ -n "$AJLOW_MANAGED_SESSIONS" ] && [ -f "$AJLOW_MANAGED_SESSIONS" ]; then
    MANAGED_MODE_SUPPORTED=true
else
    MANAGED_MODE_SUPPORTED=false
fi

MANAGED_MODE_ENABLED=false

# Collect existing session info

if [ "$#" -gt 0 ] && [ -n "$1" ]; then
    if [ "$1" == "--managed-sessions" ] && [ "$MANAGED_MODE_SUPPORTED" ]; then
        MANAGED_MODE_ENABLED=true
        declare -A sessions # session_name=session_path
        sessionKeys=""
        while read -r line; do
            key=$(echo "$line" | cut -d'=' -f1)
            val=$(echo "$line" | cut -d'=' -f2)
            sessions["$key"]="$val"
            sessionKeys="$sessionKeys\n$key"
        done < "$AJLOW_MANAGED_SESSIONS"
        sessionKeys="${sessionKeys:2}" # trim the prepended '\n'
    else 
        exit 1
    fi
else # Use results of `zellij list-sessions`
    ZJ_SESSIONS=$(zellij list-sessions)
fi 

# FZF and attach to selected session
if [ "$MANAGED_MODE_ENABLED" == true ]; then
    selection="$(echo -e "$sessionKeys" | fzf --ansi)"
    path=$(echo "${sessions[$selection]}" | envsubst)

    # Determine layout to use
    case $path in
        "$AJLOW_REPO_HOME/"*)
            layout="dev"
            ;;
        "$HOME")
            layout="home"
            ;;
        *)
            layout="default"
            ;;
    esac

    # Attach or create if necessary
    zellij attach -c "$selection" options --default-layout "$layout" --default-cwd "$path"
else
    NUM_SESSIONS=$(echo "${ZJ_SESSIONS}" | wc -l)

    if [ "${NUM_SESSIONS}" -ge 2 ]; then
        zellij attach "$(echo "${ZJ_SESSIONS}" | fzf --ansi)"
    else
        zellij attach -c
    fi
fi

