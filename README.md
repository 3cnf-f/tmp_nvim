### set envs
```bash
TMP_GITUSER="<git_username>"
TMP_GITEMAIL="<git_email>"
```

```bash
DEBIAN_FRONTEND=noninteractive && TZ=Etc/UTC && apt update && apt upgrade -y &&apt install -y nano git curl wget xz-utils zstd unzip iproute2 
```

```bash

apt install -y python3-pip python3-venv pipx python3-flask
```

```bash
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz &&rm -rf /opt/nvim &&tar -C /opt -xzf nvim-linux-x86_64.tar.gz &&\

git clone https://github.com/3cnf-f/tmp_nvim.git ~/.config/
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



```

##shit to add to .bashrc / bashaliases
```bash
cat ~/.config/addto_bashrc >>~/.bashrc &&\
cat ~/.config/addto_bashaliases >>~/.bash_aliases &&\
cat ~/.config/addt_ssh_config >>~/.ssh/config
source ~/.bashrc

```
