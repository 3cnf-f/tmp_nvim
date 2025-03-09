#!/bin/bash
echo "f_git_check() Checking git remote url"
git config --get remote.origin.url >~/.tmp_git_status.txt &&
if grep -q "http" ~/.tmp_git_status.txt ; then
  echo "you are using http remote, that doesnt work anymore"
  # Perform error handling actions
elif grep -q "git@github.com:" ~/.tmp_git_status.txt ; then
  echo "you are using ssh for remote url in this repo, good"
fi
