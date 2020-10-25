#!/usr/bin/env bash
#
#                Simple tool to setup a Nim environment
#                      Copyright (C) 2020 Leorize
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.

set -eu
set -o pipefail

_releases_url=https://github.com/nim-lang/nightlies/releases
_download_url=$_releases_url/download

print-help() {
  cat <<EOF
Usage: $0 [option] version-branch

Downloads and install the latest Nim nightly for branch 'version-branch'.
The compiler can then be found in the 'bin' folder relative to the output
directory.

This script is tailored for CI use, as such it's very barebones and make
assumptions about the system such as having a working C compiler.

Options:
    -o dir     Set the output directory to 'dir'. The compiler will be
               extracted to this directory. Defaults to \$PWD/nim.
    -h         Print this help message.
EOF
}

get-archive-name() {
  local ext=.tar.xz
  local os; os=$(uname)
  os=$(tr '[:upper:]' '[:lower:]' <<< "$os")
  case "$os" in
    'darwin')
      os=macosx
      ;;
    'windows_nt'|mingw_nt*)
      os=windows
      ext=.zip
      ;;
  esac

  local arch; arch=$(uname -m)
  case "$arch" in
    aarch64)
      arch=arm64
      ;;
    armv7l)
      arch=arm
      ;;
    i*86)
      arch=x32
      ;;
    x86_64)
      arch=x64
      ;;
  esac

  echo "${os}_$arch$ext"
}

has-release() {
  local tag=$1
  curl -f -I "$_releases_url/$tag" >/dev/null 2>&1
}

msg() {
  echo $'\e[1m\e[36m--\e[0m' "$@"
}

ok() {
  echo $'\e[1m\e[32m--\e[0m' "$@"
}

err() {
  echo $'\e[1m\e[31mError:\e[0m' "$@"
}

out=$PWD/nim
branch=
while getopts 'o:h' opt; do
  case "$opt" in
    'o')
      out=$OPTARG
      ;;
    'h')
      print-help
      exit 0
      ;;
    *)
      print-help
      exit 1
      ;;
  esac
done
unset opt

shift $((OPTIND - 1))
[[ $# -gt 0 ]] && branch=$1
if [[ -z "$branch" ]]; then
  print-help
  exit 1
fi

mkdir -p "$out"
cd "$out"

tag=latest-$branch
if has-release "$tag"; then
  archive=$(get-archive-name)
  msg "Downloading prebuilt archive '$archive' for branch '$branch'"
  if ! curl -f -LO "$_download_url/$tag/$(get-archive-name)"; then
    err "Archive '$archive' could not be found and/or downloaded. Maybe your OS/architecture does not have any prebuilt available?"
    exit 1
  fi
  msg "Extracing '$archive'"
  tar -xf "$archive" --strip-components 1
else
  err "Could not find any release named '$tag'. The provided branch ($branch) might not be tracked by nightlies, or is being updated."
  exit 1
fi

ok "Installation to '$PWD' completed! The compiler and associated tools can be found at '$PWD/bin'"
