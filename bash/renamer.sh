#!/bin/bash

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 substr replacement"
  exit 1
fi

rename_all() {
  local from="$1"
  local to="$2"

  for f in *"$from"*; do
    [ -e "$f" ] || continue           # skip if no match
    local new="${f//$from/$to}"
    mv -v -- "$f" "$new"
  done
}

rename_all "$@"

# Midnight commander:
# F9 -> Command -> Edit menu -> User: (example for a shortcut "r")
#
# + t r | t d
# r       Rename all files
#         SUBSTR=%{Enter a substring:}
#         REPLACEMENT=%{Enter a replacement:}
#         renamer.sh $SUBSTR $REPLACEMENT %s
# 
# Usage: F2
