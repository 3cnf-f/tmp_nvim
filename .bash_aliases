
source ~/bash_alias_env.env
alias f_hbr="ssh $F_HBR_USER_IP" #doc root boz
alias f_pbr="ssh $F_PBR_USER_IP" #doc podamanis boz
alias f_bubw="ssh $F_BUBW_USER_IP" #doc bubu local
alias f_bubm="ssh $F_BUBM_USER_IP" #doc bubu mesh
alias f_radxe="ssh $F_RADXE_USER_IP" #doc radxa eth0 
alias f_tabs9='scrcpy --no-video --no-audio -MK --shortcut-mod=rctrl' #turn on adb tablet control
alias nvim_me='NVIM_APPNAME=nvim_me nvim' # run personal version of nvim
alias nvim_old='NVIM_APPNAME=nvim_old nvim' # run personal version of nvim

alias f_fz_nvim='nvim $(fzf --preview="cat {}")' #doc fzf file and open in nvim

f_send_5t_sbx() { scp -i ~/.ssh/id_ed25519 -P 23 -r  "$1" $F_FIVET_USER_IP:./ ;} #doc send to sbx
f_get_5t_sbx() { scp -i ~/.ssh/id_ed25519 -P 23 -r $F_FIVET_USER_IP:/home/$1 . ;} #doc get from sbx
f_5t_sbx_command() { ssh -i ~/.ssh/id_ed25519 -p23  $F_FIVET_USER_IP $@ ;} #doc run command on sbx
f_send_hz_sbx() { scp -i ~/.ssh/id_ed25519 -P 23 -r  "$1" $F_STORAGEBOX_USER_IP:/home/ ;} #doc send to sbx
f_get_hz_sbx() { scp -i ~/.ssh/id_ed25519 -P 23 -r $F_STORAGEBOX_USER_IP:/home/$1 . ;} #doc get from sbx
f_sbx_command() { ssh -i ~/.ssh/id_ed25519 -p23  $F_STORAGEBOX_USER_IP $@ ;} #doc run command on sbx
f_bubm_get() { scp -i ~/.ssh/id_ed25519 -r $F_BUBM_USER_IP:/home/fa/$1 .;} #doc get from bubu
f_bubm_send() { scp -i ~/.ssh/id_ed25519 -r "$1" $F_BUBM_USER_IP:/home/fa/ ;} #doc send to bubu
f_hz_pbr_get() { scp -i ~/.ssh/id_ed25519 -r $F_PBR_USER_IP:/home/podamanis/$1 .;} #doc get from pbr
f_hz_pbr_send() { scp -i ~/.ssh/id_ed25519 -r "$1" $F_PBR_USER_IP:/home/podamanis/ ;} #doc send to pbr
f_cmd_pbr() { ssh -i ~/.ssh/id_ed25519  $F_PBR_USER_IP  $@ ;} #doc run command on podamanis
f_si_get() { scp -i ~/.ssh/id_ed25519 -r $F_PBR_USER_IP:/home/podamanis/silverbullet/space/$1 .;} #doc get from si
f_si_send() { scp -i ~/.ssh/id_ed25519 -r "$1" $F_PBR_USER_IP:/home/podamanis/silverbullet/space/ ;} #doc send to si
sh_phone_jump_py() { python3 ~/f_phone_jump.py $F_PHONE_JUMP_URL "$@" ;} #doc send phonenumber
sh_phone_jump_py_clip() { sh_phone_jump_py "$(xclip -selection clipboard -o)"; } #doc send clipboard to phone_jump

ls_new_py() { #doc ls new py
    find . -type d \( -name "node_modules" -o -name ".git" -o -name ".venv" -o -name "__pycache__" \) -prune \
    -o -type f -name "*.py" -print0 |
    xargs -0 ls -lth --time-style=long-iso -r |
    sed -E 's/^([^[:space:]]+[[:space:]]+){4}//' |
    column -t
}


f_py_create_repo() { #doc new py repo w readme, custom .gitignore and .codeiumignore
  local repo_name="$1"
  
  if [ -z "$repo_name" ]; then
      echo "Error: Repo name required"
      return 1
  fi
  
  if gh repo view "3cnf-f/$repo_name" &>/dev/null; then
    echo "Error: Repo $repo_name already exists on GitHub"
    return 1
  fi
  
  mkdir "$repo_name" && cd "$repo_name" || return 1
  
  git init
  gh repo create "$repo_name" --private --source=. --remote=origin
  
  # 1. Create .gitignore with custom header
  cat << 'EOF' > .gitignore
# my stuff ########
*.json
secrets.*
my_secrets.*
*.txt
!requests.txt
!requirements.txt
token.*
*.url
*.csv
*.xlsx
*.sq3
# Environments
.venv/
venv/
env/
# Neovim / Vim Swap files
*.swp
*.swo
*.swn
.*.swp
.*.swo
.*.swn
# Neovim / Vim Backup files
*.bak
*~
*.un~
# Neovim / Vim Undo files
*.undo
.netrwhist
# Session files
Session.vim
*.env
# my stuff end ########
EOF
  echo "Repository $repo_name created and initialized."
}

f_acp() { #doc pip frz add commit push
    # Check if .git exists
    if [ ! -d ".git" ]; then
        echo "Error: Not in a git repository"
        return 1
    fi
    
    # Use "f_acp: no args" if no arguments are provided
    local commit_message="${@:-f_acp: no args}"

    # Handle dependencies for both standard venv and uv
    if [ -d ".venv" ]; then
        if command -v uv &> /dev/null; then
            uv pip freeze > requirements.txt
        else
            # Explicit path prevents freezing global python if venv isn't active
            .venv/bin/pip freeze > requirements.txt
        fi
    fi

    git add . && git commit -m "$commit_message" && git push
}

t_check_nrun_venv(){ #doc tmux: activate if venv
    # Check if .venv exists
    if [ ! -d ".venv" ]; then
        echo "Error: .venv not found or initialized"
        return 1
    fi
    # This path is identical for both uv and standard python -m venvs on Linux
    source .venv/bin/activate
}
### Solution for f_ocr_img (Resolution Restricted)
f_ocr_img() {
    # 1. Dependency & File Check
    if [[ ! -f "$1" ]]; then echo "Error: File '$1' not found."; return 1; fi
    if ! command -v convert &> /dev/null; then echo "Error: Please install ImageMagick (sudo apt install imagemagick)"; return 1; fi

    # 2. Create a temporary resized version (/tmp)
    # -resize 1024x1024\> only shrinks if the image is LARGER than 1024px
    local TMP_IMG="/tmp/ollama_ocr_resize.jpg"
    convert "$1" -resize 1024x1024\> "$TMP_IMG"

    # 3. Encode the resized image
    local IMG_B64
    IMG_B64=$(base64 -w 0 "$TMP_IMG")

    # 4. Execute API Call
    # Note: Using your original prompt as requested
    curl -s http://F_BUBM_IP:11434/api/generate -d @- <<EOF | jq -r '.response'
{
  "model": "deepseek-ocr:3b",
  "prompt": "Extract the text in the image.",
  "images": ["$IMG_B64"],
  "stream": false
}
EOF

    # 5. Cleanup
    rm "$TMP_IMG"
}

f_rsi_rsync_silverbullet_inbox() { #doc sync to sb , inboxing
    if rsync -avz ~/send_to_silverbullet/not_sent/*.md $F_PBR_USER_IP:/home/podamanis/silverbullet/space/inbox/; then

     for file in ~/send_to_silverbullet/not_sent/*.md; do
        [ -f "$file" ] || continue
        newname="$(basename "$file")_$(date +%Y%m%d_%H%M%S)"
        mv "$file" ~/send_to_silverbullet/sent/"$newname"
    done
        echo "Uploaded and moved"
    else
        echo "Rsync failed, files not moved"
    fi
}
f_py_create_repo() { #doc new py repo w readme, custom .gitignore and .codeiumignore
  local repo_name="$1"
  
  if gh repo view "3cnf-f/$repo_name" &>/dev/null; then
    echo "Error: Repo $repo_name already exists on GitHub"
    return 1
  fi
  
  mkdir "$repo_name" && cd "$repo_name" || return 1
  
  git init
  gh repo create "$repo_name" --private --source=. --remote=origin
  
  # 1. Create .gitignore with YOUR custom header
  cat << 'EOF' > .gitignore
# my stuff ########
*.json
secrets.*
my_secrets.*
*.txt
token.*
*.url
*.csv
*.xlsx
*.sq3
# Neovim / Vim Swap files
*.swp
*.swo
*.swn
.*.swp
.*.swo
.*.swn
# Neovim / Vim Backup files
*.bak
*~
*.un~
# Neovim / Vim Undo files
*.undo
.netrwhist
# Session files
Session.vim
*.env
# my stuff end ########

EOF

  # 2. Append standard Python .gitignore
  echo "Downloading standard Python .gitignore..."
  curl -s https://raw.githubusercontent.com/github/gitignore/main/Python.gitignore >> .gitignore

  # 3. Create .codeiumignore (AI Exclusion List)
  # This explicitly tells AI tools not to read/index these files for context.
  cat << 'EOF' > .codeiumignore
# Credentials and Secrets
token.*
credentials.*
my_secrets.py
secrets.py
secrets/
.env
*.env
.env.local
.env.*
*.pem
*.key
id_rsa*
*.json
client_secret*

# Database files
*.db
*.sqlite3
*.sq3

# Logs
*.log
EOF

  # 4. Copy to .cursorignore (covers Cursor AI as well)
  cp .codeiumignore .cursorignore

  # Setup README
  echo "# $repo_name" > README.md
  
  # Setup venv
  python3 -m venv .venv
  
  # Open editor
  nvim README.md
  
  # Commit and push
  git add .
  git commit -m "first commit"
  git branch -M main
  git push -u origin main
}


