import re
import sys
import os
title = "Phone Jump"
env_url = sys.argv[1]

command_line_args = sys.argv
#concatenate the command line arguments into a single string
input= ' '.join(command_line_args[2:])
command_line_args = ''.join(command_line_args[2:])
command_line_args=command_line_args.replace("(", "")
command_line_args=command_line_args.replace(")", "")
command_line_args=command_line_args.replace("-", "")
command_line_args=command_line_args.replace(" ", "")
if command_line_args.startswith('+46') :
    command_line_args=command_line_args[3:]
    command_line_args="0"+command_line_args
if command_line_args.startswith('0046') :
    command_line_args=command_line_args[4:]
    command_line_args="0"+command_line_args
if command_line_args.isdigit():
    message = f'Calling {command_line_args}'
    os.system(f'notify-send "{title}" "{message}"')
    os.system(f' /usr/bin/google-chrome-stable {env_url}{command_line_args}')
else:
    message = f'Invalid phone number: {command_line_args}'

os.system(f'notify-send "{title}" "{message}"')
print(command_line_args)
print(f'url={env_url}')
