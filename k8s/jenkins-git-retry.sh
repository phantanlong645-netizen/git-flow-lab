#!/bin/sh

# Jenkins controller wrapper for transient GitHub/proxy TLS failures.
# Non-network Git commands are delegated without retries.
case "${1:-}" in
    fetch|ls-remote|clone)
        attempt=1
        max_attempts=5

        while [ "$attempt" -le "$max_attempts" ]; do
            /usr/bin/git "$@" && exit 0
            status=$?

            if [ "$attempt" -eq "$max_attempts" ]; then
                exit "$status"
            fi

            delay=$((attempt * 2))
            printf >&2 'Git network command failed (attempt %s/%s); retrying in %ss...\n' \
                "$attempt" "$max_attempts" "$delay"
            sleep "$delay"
            attempt=$((attempt + 1))
        done
        ;;
    *)
        exec /usr/bin/git "$@"
        ;;
esac
