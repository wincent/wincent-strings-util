#!/bin/sh -e
# Copyright 2009 Wincent Colaiuta.

. "buildtools/Common.sh"

# print warning if current HEAD is not a signed/annotated tag
TAGGED=""

# for signed tags this will be "2.0" or similar
# for unsigned tags or untagged commits will be "2.0-5-g08867ea" or similar
HEAD=$(git describe)
for TAG in $(git tag)
do
  if [ $TAG = $HEAD ]; then
    TAGGED=$TAG
  fi
done
if [ -z "$TAGGED" ]; then
  warn "current HEAD is not tagged/annotated, but it should be for official releases"
fi

# prep binary -> zip installer pkg

# prep source archive
# including submodules

# prep release notes

# prep plaintext version of manpage