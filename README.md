### tpm install/reload notes
```
Install plugins: Press Ctrl-b then Shift-I (capital I). This fetches and installs the plugins listed in your config.
TPM will clone the plugins into ~/.tmux/plugins/. It may take a moment—watch for output like "TPM: plugins installed."
Exit tmux: Press Ctrl-b then d to detach (session persists).
Step 6: Test and Use
Reattach to the session: tmux attach (or tmux a for short).
Verify plugins: For example, if you added tmux-resurrect, press Ctrl-b then Ctrl-s to save the session, or Ctrl-r to restore.
To add/remove plugins later: Edit ~/.tmux.conf, reload with Ctrl-b :source ~/.tmux.conf, then Ctrl-b Shift-I to update.
```


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
DEBIAN_FRONTEND=noninteractive && TZ=Etc/UTC && apt update && apt upgrade -y &&apt install -y locales nano git curl wget xz-utils zstd unzip iproute2 
```

## get nvim and clone this repo
```bash
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz &&rm -rf /opt/nvim &&tar -C /opt -xzf nvim-linux-x86_64.tar.gz &&\

git clone https://github.com/3cnf-f/tmp_nvim.git ~/.config/
```

##shit to add to .bashrc / bashaliases
```bash
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

install tmux w tpm plugins
```bash
cat ~/.config/.tmux.conf >>~/.tmux.conf &&\
mkdir -p ~/.tmux/plugins &&\
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm &&\

echo &&\
echo "******" &&\
echo "§ is prefix, ä is reload tmux.conf" &&\echo &&\
echo "*******" &&\
echo "On first run do leader +ä to load conf" && echo &&\
echo "then leader + I to install tpm plugins" && echo &&\
echo "try leader +s to save session" && echo &&\
echo "or leader +r t" && echo &&\
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


