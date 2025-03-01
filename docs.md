### adds to bashrc
```bash
alias nvfz='nvim $(fzf --preview="cat {}")'
export PATH="$PATH:/opt/nvim-linux-x86_64/bin"

[ -f ~/.fzf.bash ] && source ~/.fzf.bash
```
