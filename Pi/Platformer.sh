#!/bin/sh
echo -ne '\033c\033]0;Platformer\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Platformer.arm64" "$@"
