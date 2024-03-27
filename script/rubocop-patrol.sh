#!/bin/bash

rubocop="`dirname $0`/../bin/rubocop"
dir="${1-.}"

inotifywait -r -m -e CLOSE_WRITE "$dir" |
  grep '\.rb$' --line-buffered |
  while read path _ file; do
      $rubocop --autocorrect "$path$file"
  done
