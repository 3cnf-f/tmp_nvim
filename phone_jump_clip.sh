#!/bin/bash
source ~/bash_alias_env.env
python3 ~/f_phone_jump.py  $F_PHONE_JUMP_URL "$(xclip -selection clipboard -o)"
# python3 ~/f_phone_jump.py "$(xclip -selection clipboard -o)"
