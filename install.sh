#!/usr/bin/env bash
# Installs the ssqch release named by $VERSION (or the latest one) for this runner,
# checks it against the release's SHA-256 checksum, and adds it to the PATH.
set -euo pipefail

repo=reverentgeek/sitesquatch
version="${VERSION:-latest}"
version="${version#v}"

case "$RUNNER_OS-$RUNNER_ARCH" in
  Linux-X64) target=x86_64-unknown-linux-musl ext=tar.gz bin=ssqch ;;
  macOS-ARM64) target=aarch64-apple-darwin ext=tar.gz bin=ssqch ;;
  macOS-X64) target=x86_64-apple-darwin ext=tar.gz bin=ssqch ;;
  Windows-X64) target=x86_64-pc-windows-msvc ext=zip bin=ssqch.exe ;;
  *) echo "::error::ssqch has no prebuilt binary for $RUNNER_OS on $RUNNER_ARCH"; exit 1 ;;
esac

if [ "$version" = latest ]; then
  auth=()
  [ -n "${TOKEN:-}" ] && auth=(-H "Authorization: Bearer $TOKEN")
  version=$(curl -fsSL ${auth[@]+"${auth[@]}"} "https://api.github.com/repos/$repo/releases/latest" | sed -n 's/.*"tag_name": *"v\([^"]*\)".*/\1/p' | head -n 1)
  [ -n "$version" ] || { echo "::error::Couldn't find the latest ssqch release"; exit 1; }
fi

posix() { if command -v cygpath >/dev/null; then cygpath -u "$1"; else printf '%s\n' "$1"; fi; }
native() { if command -v cygpath >/dev/null; then cygpath -w "$1"; else printf '%s\n' "$1"; fi; }

dir="$(posix "$RUNNER_TOOL_CACHE")/ssqch/$version/$target"
if [ -f "$dir/$bin" ]; then
  echo "ssqch $version is already in the tool cache"
else
  archive="ssqch-$target.$ext"
  url="https://github.com/$repo/releases/download/v$version/$archive"
  work="$(posix "$RUNNER_TEMP")/setup-ssqch-$$"
  mkdir -p "$work"
  echo "Downloading $url"
  curl -fsSL --retry 3 -o "$work/$archive" "$url" || { echo "::error::Couldn't download ssqch $version for $target ($url)"; exit 1; }
  curl -fsSL --retry 3 -o "$work/$archive.sha256" "$url.sha256"

  expected=$(cut -d ' ' -f 1 < "$work/$archive.sha256")
  if command -v sha256sum >/dev/null; then
    actual=$(sha256sum "$work/$archive" | cut -d ' ' -f 1)
  else
    actual=$(shasum -a 256 "$work/$archive" | cut -d ' ' -f 1)
  fi
  [ "$expected" = "$actual" ] || { echo "::error::$archive doesn't match its checksum (expected $expected, got $actual)"; exit 1; }

  mkdir -p "$work/out" "$dir"
  if [ "$ext" = zip ]; then
    unzip -q "$work/$archive" -d "$work/out"
    mv "$work/out/$bin" "$dir/$bin"
  else
    tar -xzf "$work/$archive" -C "$work/out"
    mv "$work/out/ssqch-$target/$bin" "$dir/$bin"
    chmod +x "$dir/$bin"
  fi
  rm -rf "$work"
fi

native "$dir" >> "$GITHUB_PATH"
echo "version=$version" >> "$GITHUB_OUTPUT"
echo "path=$(native "$dir")" >> "$GITHUB_OUTPUT"
echo "Installed ssqch $version ($target)"
