#!/bin/sh
set -eu

API_BASE="${CRABYARD_API_URL:-https://crabyard-api-production.up.railway.app}"
BIN_NAME="crabyard"
INSTALL_DIR="${CRABYARD_INSTALL_DIR:-$HOME/.crabyard/bin}"
tmpdir=""

err() {
    printf 'error: %s\n' "$1" >&2
    exit 1
}

for cmd in curl tar uname mktemp awk; do
    command -v "$cmd" >/dev/null 2>&1 || err "Required command '$cmd' not found"
done

case "$(uname -s)" in
    Linux*) os="unknown-linux-gnu" ;;
    Darwin*) os="apple-darwin" ;;
    *) err "Use install.ps1 on Windows; this installer supports macOS and Linux" ;;
esac
case "$(uname -m)" in
    x86_64|amd64) arch="x86_64" ;;
    aarch64|arm64) arch="aarch64" ;;
    *) err "Unsupported architecture: $(uname -m)" ;;
esac
target="${arch}-${os}"
version="${CRABYARD_VERSION:-$(curl -fsSL --retry 3 --connect-timeout 10 "${API_BASE%/}/cli/latest" | sed -n 's/.*"version": *"\([^"]*\)".*/\1/p')}"
[ -n "$version" ] || err "Could not determine the CLI release version"

printf 'Installing crabyard %s (%s)...\n' "$version" "$target"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' 0
trap 'exit 1' HUP INT TERM
url="${API_BASE%/}/cli/download/${target}?version=${version}"
archive="${tmpdir}/crabyard.tar.gz"
curl -fsSL --retry 3 --connect-timeout 10 --max-time 180 "$url" -o "$archive"
curl -fsSL --retry 3 --connect-timeout 10 --max-time 30 "${url}&checksum=1" -o "${tmpdir}/checksum"
expected="$(awk 'NR == 1 { print $1 }' "${tmpdir}/checksum")"
[ "${#expected}" -eq 64 ] || err "Invalid release checksum"
case "$expected" in *[!0-9a-fA-F]*) err "Invalid release checksum" ;; esac
if command -v sha256sum >/dev/null 2>&1; then
    actual="$(sha256sum "$archive" | awk '{ print $1 }')"
elif command -v shasum >/dev/null 2>&1; then
    actual="$(shasum -a 256 "$archive" | awk '{ print $1 }')"
else
    err "Install sha256sum or shasum to verify the download"
fi
[ "$(printf '%s' "$expected" | tr 'A-F' 'a-f')" = "$actual" ] || err "Release checksum mismatch"
tar -xzf "$archive" -C "$tmpdir" "$BIN_NAME"
[ -f "${tmpdir}/${BIN_NAME}" ] && [ ! -L "${tmpdir}/${BIN_NAME}" ] || err "Archive does not contain the CLI binary"
mkdir -p "$INSTALL_DIR"
mv "${tmpdir}/${BIN_NAME}" "${INSTALL_DIR}/${BIN_NAME}"
chmod +x "${INSTALL_DIR}/${BIN_NAME}"
printf 'Installed to %s/%s\n' "$INSTALL_DIR" "$BIN_NAME"
case ":$PATH:" in
    *":$INSTALL_DIR:"*) ;;
    *) printf 'Add the CLI to your shell profile: export PATH="%s:$PATH"\n' "$INSTALL_DIR" ;;
esac
printf "Done. Run 'crabyard --help' to get started.\n"
