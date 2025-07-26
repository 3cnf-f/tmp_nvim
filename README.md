

### setup windsurf, to get the token from a container w no clipboard or browser capabilities
```
https://windsurf.com/profile?response_type=token&redirect_uri=vim-show-auth-token
```

### set envs
```bash
TMP_GITUSER="<git_username>"
TMP_GITEMAIL="<git_email>"
```

```bash
DEBIAN_FRONTEND=noninteractive && TZ=Etc/UTC && apt update && apt upgrade -y &&apt install -y locales nano git curl wget xz-utils zstd unzip iproute2 tmux
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
cat ~/.config/addto_ssh_config >>~/.ssh/config &&
source ~/.bashrc

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
git remote set-url origin git@github.com:<github_user>/<repo_name>.git

```

## setup git for add and commit
```
git config --global gpg.format ssh &&\
git config --global user.signingkey ~/.ssh/git_ed25519.pub &&\
git config --global commit.gpgsign true &&\

## to make an identical branch as backup
```
Clone repo if needed: git clone <repo-url>
Navigate: cd <repo-folder>
Update main: git checkout main && git pull
Create branch: git checkout -b backup-branch
Push branch: git push origin backup-branch
Switch to main: git checkout main
```


```


