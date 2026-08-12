

#ALWAYS specify these for less bullcrap
```
podman run -it \
  -e LANG=C.UTF-8 \
  -e TERM=xterm-256color \
  -e TZ=Europe/Stockholm \
  -e DEBIAN_FRONTEND=noninteractive \
  --restart=unless-stopped \
  docker.io/debian:latest /bin/bash

```

## If running containers with cuda adapt the following
```
podman run --rm --device nvidia.com/gpu=all docker.io/library/ubuntu:24.04 nvidia-smi
```


## til for loads of stuff including tmux and nvim
https://github.com/jbranchaud/til

### setup windsurf, to get the token from a container w no clipboard or browser capabilities
```
https://windsurf.com/profile?response_type=token&redirect_uri=vim-show-auth-token
```

# install tty-copy
```
curl -L -o /usr/local/bin/tty-copy https://github.com/jirutka/tty-copy/releases/download/v0.2.2/tty-copy.x86_64-linux \&&
chmod +x /usr/local/bin/tty-copy
```

### paste secret email
```bash
export TMP_GITEMAIL=""
```
```
git config --global user.email $TMP_GITUSER  \&&
git config --global user.name 3cnf-f

```

```bash
apt update && apt upgrade -y &&apt install -y --no-install-recommends build-essential nano git curl wget xz-utils zstd unzip iproute2 tmux pipx sudo fd-find ripgrep

```

## install upload download
```
wget https://github.com/trzsz/trzsz-go/releases/download/v1.2.0/trzsz_1.2.0_linux_x86_64.deb &&\
dpkg -i trzsz_1.2.0_linux_x86_64.deb &&\
rm trzsz_1.2.0_linux_x86_64.deb

```
## install github cli
```bash
(type -p wget >/dev/null || (sudo apt update && sudo apt install wget -y)) \
	&& sudo mkdir -p -m 755 /etc/apt/keyrings \
	&& out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
	&& cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
	&& sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
	&& sudo mkdir -p -m 755 /etc/apt/sources.list.d \
	&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
	&& sudo apt update \
	&& sudo apt install gh -y \
	&& gh auth login
```

### install jedi language server and debugpy
remember debugby needs pip install debugby in each venv
```
pipx install jedi-language-server &&\
apt install python3-debugpy -y

```
### install treesitter
ˋˋˋ
curl -LO https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-linux-x64.gz && gzip -d tree-sitter-linux-x64.gz && chmod +x tree-sitter-linux-x64 && chown root:root tree-sitter-linux-x64 &&  mv tree-sitter-linux-x64 /usr/local/bin/tree-sitter
ˋˋˋ 

## get nvim and clone this repo
```bash
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz &&rm -rf /opt/nvim &&tar -C /opt -xzf nvim-linux-x86_64.tar.gz &&\

git clone https://github.com/3cnf-f/tmp_nvim.git ~/.config/
```

##shit to add to .bashrc / bashaliases
##move .tmux.conf,  install tpm
```bash
cat ~/.config/.tmux.conf >>~/.tmux.conf &&\
mkdir -p ~/.tmux/plugins &&\
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm &&\
cat ~/.config/addto_bashrc >>~/.bashrc &&\
cat ~/.config/.bash_aliases >>~/.bash_aliases &&\
mkdir ~/.ssh &&\
cat ~/.config/addto_ssh_config >>~/.ssh/config &&\
source ~/.bashrc &&\
mkdir -p ~/.ipython/profile_default/startup/ &&\
cp ~/.config/panes_ipython_dump.py ~/.ipython/profile_default/startup/ &&\
cp ~/.config/f_phone_jump.py ~/ &&\
cp ~/.config/phone_jump_clip.sh ~/

```
## install herdr

```
curl -fsSL https://herdr.dev/install.sh | sh
```
# shit to add to /etc/hosts for blocking yt for example
```bash
cat ~/.config/addto_etc_hosts >>/etc/hosts
```






```bash

apt install -y python3-pip python3-venv pipx python3-ipython
```


##install fzf

```bash
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf &&\
~/.fzf/install --all
```

## create ssh key for git
```bash
ssh-keygen -t ed25519 -C $(TMP_GITEMAIL) -f ~/.ssh/git_ed25519 
```

## when in a repo setup git remote url so that it doesnt try to acess with http
```bash
git remote set-url origin <git ssh url>

```

## add commit push

```
git add . &&\
git commit -m "yes" &&\
git push
```



## setup git for add and commit
## to make an identical branch as backup
```
git config --global gpg.format ssh &&\
git config --global user.signingkey ~/.ssh/git_ed25519.pub &&\
git config --global commit.gpgsign true

```

Create branch: 
```
git checkout -b backup-branch
git checkout -b flash
git commit -a
git push --set-upstream origin flash
git push
```


## to run a ttyd on port 11011 with fonts
### install binary that contains fonts
```
[ -d ~/.local/bin ] || mkdir -p ~/.local/bin &&\
wget https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.x86_64 &&\
mv ttyd.x86_64 ttyd &&\
chmod +x ttyd &&\
mv ttyd ~/.local/bin/ttyd 
```

### then run:
```
ttyd -p 11011 -W /bin/bash
```

### if on host running on container
```
podman exec -d win_nvim_dev /root/.local/bin/ttyd -W -p 11310 -t enableTrzsz=true -t enableSixel=true -t enableZmodem=true /bin/bash
```
### to join a running tmux session called work but allow for independant navigation:
```
tmux new-session -t work -s browser_view
```
### to create a session called font_monk on a new server called omy omyserver with specified config file
### and how to attach a new-session to that session
```
tmux -L omyserver -f ~/.tmux.omyarchy.conf new-session -s font_monk
tmux -L omyserver new-session -t font_monk -s att_font_monk

```
## Other stuff:
 
```
save pip requirements but only modules that are used
pip install pipreqs

# Scan recursively but ignore common non-source directories
pipreqs . --ignore .venv,venv,archive,tests,__pycache__,.pytest_cache,.git --force

```

large file dl from google drive with curl

```
curl "https://drive.usercontent.google.com/download?id={fileId}&confirm=xxx" -o filename
```

pass files that end in .py and contain "import" to fzf as file picker for nvim
```
nvim $(rg --line-number --no-heading --color=always import ./src | fzf --ansi --preview 'echo {} | cut -d: -f1 | xargs batcat --color=always' | cut -d: -f1)
```

#set shorcut for phone jump in your window manager 
```
/home/username/phone_jump_clip.sh
```
Åv shortcut in nvim needs tmux pantitle plugin, pip install visidata and a local copy of the f_visixxx .py

# herdr remote login, allows for local clipboard acess
herdr --remote ssh://you@server:2222
