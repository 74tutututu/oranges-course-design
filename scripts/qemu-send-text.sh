#!/usr/bin/env bash

set -euo pipefail

for text in "$@"; do
    for ((index = 0; index < ${#text}; index++)); do
        character="${text:index:1}"
        case "${character}" in
            ' ')
                key=spc
                ;;
            '.')
                key=dot
                ;;
            '-')
                key=minus
                ;;
            *)
                key="${character}"
                ;;
        esac
        printf 'sendkey %s\n' "${key}"
        sleep 0.02
    done
    printf 'sendkey ret\n'
    sleep 0.1
done
