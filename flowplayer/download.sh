#!/bin/sh

set -e

VERSION="5.4.6"
JQUERY_VERSION="2.1.1"

echo "See latest version at https://flowplayer.org/latest/ or https://github.com/flowplayer/flowplayer or https://flowplayer.org/docs/setup.html"

# Try to download the latest version automatically
TEMP="$(curl -s "https://flowplayer.org/latest/" | grep -i href=.*flowplayer.org.*/.*zip | sed "s_.*href=\"\([^\"]*\)\".*_https:\1_" | head -n 1)"
if [[ -n "$TEMP" ]]; then
  HOST="${TEMP%/*}"
  ZIPFILE="${TEMP##*/}"
  DIR="$(echo "${ZIPFILE%.*}" | sed s_^[^0-9]*__)"
else
  echo "Unable to download the latest version automatically, consider updating this script now." >&2
  HOST="https://releases.flowplayer.org/${VERSION}"
  ZIPFILE="flowplayer-${VERSION}.zip"
  DIR="${VERSION}"
fi

rm -f "${ZIPFILE}"
wget "${HOST}/${ZIPFILE}" || exit 1
rm -rf "./$DIR" ; mkdir -p "./$DIR"
unzip -x "${ZIPFILE}" -d "./$DIR"
wget "https://code.jquery.com/jquery-${JQUERY_VERSION}.min.js" -O "./$DIR/jquery.min.js"
rm "${ZIPFILE}"
rm -f "./${DIR}"/*.{html,md,swf}

rm -f latest
ln -s "$DIR" latest

echo "Created '$DIR'"

# Todo, do a diff to figure out if sed actually did something
if ! sed -i "s_^\(.flowplayer.is-fullscreen{.*background-image:[^\!]*\) \!important\(.*\)_\1\2_" "./$DIR/skin/functional.css" ; then
  echo "WARNING: Unable to patch css files for fullscreen poster support." >&2
fi
