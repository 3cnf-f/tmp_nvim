#!/bin/sh
# popup.sh — body of the f-herdr herdr popup pane.
#
# herdr runs this with cwd = this plugin root and, per open, F_HERDR_POPUP_FILE
# pointing at a file nvim just wrote. Printing that file is the whole job: the
# content never passes through a shell word, so nothing in a buffer or filename
# can be interpreted as code.
#
# When this process exits herdr closes the popup, so the trailing read is what
# keeps the popup on screen until the user dismisses it.

set -u

file="${F_HERDR_POPUP_FILE:-}"

if [ -n "$file" ] && [ -f "$file" ]; then
	cat -- "$file"
else
	echo "f-herdr popup: no content"
	echo "F_HERDR_POPUP_FILE=${file:-<unset>}"
fi

printf '\n-- any key to close --'

# Read exactly one keypress without echoing it. Falls back to a line read when
# stdin is not a tty (e.g. if this is ever run outside a herdr pane).
if [ -t 0 ]; then
	saved=$(stty -g 2>/dev/null) || saved=''
	stty raw -echo 2>/dev/null
	dd bs=1 count=1 >/dev/null 2>&1
	[ -n "$saved" ] && stty "$saved" 2>/dev/null
else
	read -r _ignored
fi
