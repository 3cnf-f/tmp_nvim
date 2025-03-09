
alias nvfz='nvim $(fzf --preview="cat {}")'

alias g-acm='git add . && git commit -a -m "g-acm alias" && git push'

 
f_git_check() {
  echo "f_git_check() Checking git remote url"

  git config --get remote.origin.url > ~/.tmp_git_status.txt && {
    if grep -q "http" ~/.tmp_git_status.txt; then
      echo "you are using http remote, that doesn't work anymore"
    elif grep -q "git@github.com:" ~/.tmp_git_status.txt; then
      echo "you are using ssh for remote url in this repo, good"
    else
      echo "Remote URL is neither HTTP nor SSH (git@github.com:). Please check."
    fi
    rm ~/.tmp_git_status.txt # Clean up the temp file.
  } || {
    echo "Error: Could not retrieve remote.origin.url or not a git repository."
  }
}


