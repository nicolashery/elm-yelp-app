#!/bin/sh
#
# Watches Elm source files and re-compiles on changes

MAIN=src/Main.elm
WATCH=src/

if [ -z $(which fswatch) ]; then
  echo "Please install fswatch before running this script"
  exit 1
fi

echo "Compiling $MAIN..."
elm-make $MAIN
echo "Watching $WATCH for changes..."
fswatch -o $WATCH | xargs -n1 -I{} elm-make $MAIN
