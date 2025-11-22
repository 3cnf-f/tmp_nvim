#ALWAYS specify -e LANG=C.UTF-8 when running a container for åäö support
```
podman  run -it -e LANG=C.UTF-8  docker.io/ubuntu:latest /bin/bash

```

## til for loads of stuff including tmux and nvim
https://github.com/jbranchaud/til

### setup windsurf, to get the token from a container w no clipboard or browser capabilities
```
https://windsurf.com/profile?response_type=token&redirect_uri=vim-show-auth-token
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
DEBIAN_FRONTEND=noninteractive && TZ=Etc/UTC && apt update && apt upgrade -y &&apt install -y locales nano git curl wget xz-utils zstd unzip iproute2 tmux pipx
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
apt install python3-debugpy

```

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
cat ~/.config/addto_bashaliases >>~/.bash_aliases &&\
mkdir ~/.ssh &&\
cat ~/.config/addto_ssh_config >>~/.ssh/config &&\
source ~/.bashrc

```

# shit to add to /etc/hosts for blocking yt for example
```bash
cat ~/.config/addto_etc_hosts >>/etc/hosts
```




## set locales .. move this to a addto .bash

```bash  sv_SE.UTF-8
apt-get install -y locales \
    && cat ~/.config/add_locale_to_bashrc >> ~/.bashrc \
    && cat ~/.config/addto_def_locale >> /etc/default/locale \
    && cat ~/.config/addto_locale_gen >>  /etc/locale.gen\



    && locale-gen \
   
```



```bash

apt install -y python3-pip python3-venv pipx python3-flask
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
