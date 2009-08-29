#!/bin/sh -e
# Copyright 2009 Wincent Colaiuta.

. "buildtools/Common.sh"

# print warning if current HEAD is not a signed/annotated tag
TAGGED=""

# for signed tags $HEAD will be "2.0" or similar
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
  TAGGED=$HEAD
fi

# prep binary -> zip installer pkg
rm -f "$BUILT_PRODUCTS_DIR/$PROJECT-$TAGGED.zip"
zip -j "$BUILT_PRODUCTS_DIR/$PROJECT-$TAGGED.zip" \
       "$BUILT_PRODUCTS_DIR/WincentStringsUtility.pkg"

# prep source archive
git archive $TAGGED > "$BUILT_PRODUCTS_DIR/$PROJECT-$TAGGED-src.tar"

# add submodules to archive
git ls-tree $TAGGED | grep '^160000 ' | \
while read mode type sha1 path
do
  rm -rf "$PROJECT_TEMP_DIR/$PROJECT-$TAGGED-$path-src/$path"
  mkdir -p "$PROJECT_TEMP_DIR/$PROJECT-$TAGGED-$path-src/$path"
  (cd $path && git archive $sha1 | tar -xf - -C "$PROJECT_TEMP_DIR/$PROJECT-$TAGGED-$path-src/$path")
  tar -rf "$BUILT_PRODUCTS_DIR/$PROJECT-$TAGGED-src.tar" \
       -C "$PROJECT_TEMP_DIR/$PROJECT-$TAGGED-$path-src" $path
done
bzip2 -f "$BUILT_PRODUCTS_DIR/$PROJECT-$TAGGED-src.tar"

# prep release notes
NOTES="$BUILT_PRODUCTS_DIR/$PROJECT-$TAGGED-release-notes.txt"
"$BUILDTOOLS_DIR/ReleaseNotes.sh" > $NOTES
git ls-tree $TAGGED | grep '^160000 ' | \
while read mode type sha1 path
do
  SUBMODULE_NOTES=$(cd $path && "$BUILDTOOLS_DIR/ReleaseNotes.sh" --tag-prefix="wincent-strings-util-")
  if [ $(echo "$SUBMODULE_NOTES" | wc -l) -ne 1 ]; then
    echo -n "$path: " >> $NOTES
    echo "$SUBMODULE_NOTES" >> $NOTES
  fi
done

NOTES="$BUILT_PRODUCTS_DIR/$PROJECT-$TAGGED-detailed-release-notes.txt"
"$BUILDTOOLS_DIR/ReleaseNotes.sh" --long > $NOTES
git ls-tree $TAGGED | grep '^160000 ' | \
while read mode type sha1 path
do
  SUBMODULE_NOTES=$(cd $path && "$BUILDTOOLS_DIR/ReleaseNotes.sh" --long --tag-prefix="wincent-strings-util-")
  if [ $(echo "$SUBMODULE_NOTES" | wc -l) -ne 1 ]; then
    echo -n "$path: " >> $NOTES
    echo "$SUBMODULE_NOTES" >> $NOTES
  fi
done

# prep plaintext version of manpage