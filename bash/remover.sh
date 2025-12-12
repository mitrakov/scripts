#!/usr/bin/env bash
set -euo pipefail

TO_DIR=/Users/director/papelera

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 files-to-delete..."
  exit 1
fi

remove_all() {
  mv -v -- "$1" "$TO_DIR"
}

remove_all "$@"

# Midnight commander:
# F9 -> Command -> Edit menu -> User: (example for a shortcut "d")
#
# + t r | t d
# d       Delete file to tommy papelera
#         remover.sh %s
# 
# Usage: F2
