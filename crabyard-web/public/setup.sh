#!/bin/sh
set -eu

API_BASE="${CRABYARD_API_URL:-https://crabyard-api-production.up.railway.app}"
INSTALL_DIR="${CRABYARD_INSTALL_DIR:-$HOME/.crabyard/bin}"
INSTALLER_URL="https://crabyard.dev/install.sh"

command -v curl >/dev/null 2>&1 || { printf 'error: curl is required\n' >&2; exit 1; }
version="${CRABYARD_VERSION:-$(curl -fsSL --retry 3 --connect-timeout 10 "${API_BASE%/}/cli/latest" | sed -n 's/.*"version": *"\([^"]*\)".*/\1/p')}"
[ -n "$version" ] || { printf 'error: Could not determine the CLI release version\n' >&2; exit 1; }
cli="$(command -v crabyard || true)"
current=""
if [ -n "$cli" ]; then
    current="$("$cli" --version 2>/dev/null | awk '{ print $NF }')"
fi
if [ -z "$cli" ] || [ "${current#v}" != "${version#v}" ]; then
    installer="$(mktemp)"
    trap 'rm -f "$installer"' 0
    trap 'exit 1' HUP INT TERM
    curl -fsSL --retry 3 --connect-timeout 10 "$INSTALLER_URL" -o "$installer"
    CRABYARD_VERSION="$version" sh "$installer"
    cli="${INSTALL_DIR}/crabyard"
fi
if ! command -v bun >/dev/null 2>&1; then
    command -v bash >/dev/null 2>&1 || { printf 'error: bash is required to install Bun\n' >&2; exit 1; }
    bun_installer="$(mktemp)"
    curl -fsSL --retry 3 --connect-timeout 10 https://bun.sh/install -o "$bun_installer"
    bash "$bun_installer"
    rm -f "$bun_installer"
    export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
    export PATH="$BUN_INSTALL/bin:$PATH"
fi
printf '\nStarting project wizard...\n\n'
if [ -t 0 ]; then
    exec "$cli" new "$@"
elif [ -t 1 ]; then
    exec "$cli" new "$@" </dev/tty
else
    printf 'error: Run crabyard new from an interactive terminal, or pass CLI flags directly\n' >&2
    exit 1
fi
