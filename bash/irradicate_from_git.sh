#! /usr/bin/bash

# Deletes a file/path from all the check in history in git.
# I believe it only works on the current branch, but use it with caution!!

export file_path_to_delete=${1}

git filter-branch --force --index-filter \
  'git rm -r --cached --ignore-unmatch ${file_path_to_delete}' \
     --prune-empty --tag-name-filter cat -- --all
