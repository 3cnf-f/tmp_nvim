#!/bin/sh
# shell.sh — body of the f-herdr "shell" popup entrypoint.
#
# A herdr popup pane is a terminal running a process, so a popup that runs bash
# is just a popup whose process is a shell. herdr closes the popup when this
# exits.
#
# Deliberately takes no command: nvim drives the shell afterwards over the
# socket (pane.send_text + pane.send_keys), so no caller-supplied string is ever
# interpolated into a shell word here.
#
# The directory to start in arrives as F_HERDR_SHELL_CWD in the per-open `env`
# map — NOT as plugin.pane.open's `cwd` field. herdr resolves this manifest's
# relative command ("sh shell.sh") against the pane's cwd, so setting that cwd
# to the caller's project directory makes this script unfindable: the popup
# process dies with `sh: 0: cannot open shell.sh` (exit 2) before it is ever
# drawn, and the only symptom the caller sees is a pane that never appears.

# F_HERDR_SHELL_CMD, if set, is run once before the interactive shell takes
# over. This is the only way to get a command into a popup: a popup pane has no
# pane_id anywhere in the socket API, so pane.send_text cannot reach it.
#
# The value is handed to the shell as its -c script argument. It is never
# spliced into a command line here, so the popup runs exactly the one command
# the caller sent and nothing built out of it.

set -u

shell="${SHELL:-/bin/sh}"

dir="${F_HERDR_SHELL_CWD:-}"
if [ -n "$dir" ] && [ -d "$dir" ]; then
	cd -- "$dir" || :
fi

cmd="${F_HERDR_SHELL_CMD:-}"
if [ -n "$cmd" ]; then
	"$shell" -c "$cmd"
	printf '\n[exit %s] -- shell below, ctrl-d closes the popup --\n' "$?"
fi

exec "$shell" -i
