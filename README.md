```bash
apt update && apt upgrade -y &&apt install -y nano git curl wget xz-utils zstd unzip iproute2 
```

```bash

apt install -y python3-pip python3-venv pipx python3-flask
```

```bash
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz &&rm -rf /opt/nvim &&tar -C /opt -xzf nvim-linux-x86_64.tar.gz &&\

git clone https://github.com/3cnf-f/tmp_nvim.git ~/.config
```
##install fzf

```bash
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf &&\
~/.fzf/install
```

##shit to add to .bashrc
```bash
cat >>~/.bashrc<<__EOF__

export PATH="$PATH:/opt/nvim-linux-x86_64/bin"
__EOF__
```

##shit to add to bash_aliases
```bash
cat >>~/.bash_aliases<<__EOF__
 

alias nvfz='nvim $(fzf --preview="cat {}")'

alias g-acm='git add . && git commit -a -m "g-acm alias" && git push'
__EOF__
```
