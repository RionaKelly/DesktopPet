#!/bin/sh
printf '\033c\033]0;%s\a' DesktopPet
base_path="$(dirname "$(realpath "$0")")"
"$base_path/DesktopPet.x86_64" "$@"
