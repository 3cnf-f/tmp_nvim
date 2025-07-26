 # Neovim/Vim Ultimate Cheat Sheet

## Text Objects
```vim
iw   " inside word (diw/yiw)
i"   " inside quotes (di")
a"   " around quotes (da")
ip   " inside paragraph
```

## Navigation
```vim

gg/G      " first/last line
#G        " jump to line #
0/$       " start/end of line
^/I       " first non-blank
%         " matching bracket
Ctrl+f/b  " page down/up
Ctrl+d/u  " half page down/up
f/F char  " find char forward/back
t/T char  " till char forward/back
*         " find word under cursor
```

## Editing
```vim
cc        " change line
C         " change to EOL
ciw/ci"   " change in word/quotes
r/R       " replace char/until ESC
d$        " delete to EOL
diw/di"   " delete in word/quotes
.         " repeat last change
u/Ctrl+r  " undo/redo
```

## Visual Mode
```vim
v         " character-wise
V         " line-wise
Ctrl+v    " block-wise
gv        " reselect last
gc        " toggle comment
:'<,'>norm cmd " apply command
```

## Macros
```vim

qh        " record to h
q         " stop recording
@h        " execute macro h
@@        " repeat last macro
```

## Windows/Tabs
```vim

Ctrl+w v  " vertical split
Ctrl+w s  " horizontal split
Ctrl+w hjkl " navigate splits
:tabnew   " new tab
gt/gT     " next/prev tab
```

## Search/Replace
```vim

/pattern  " search forward
?pattern  " search backward
n/N       " next/prev match
:%s/old/new/g " global replace
Plugins
```

## nvim-surround
```vim

ysiw)     " surround word with ()
ds)       " delete surrounding ()
cs])      " change [] to ()

## Telescope
```vim

<leader>ff " find files
<leader>fg " live grep
<leader>fb " buffers
```

## VS Code Specific
```vim

Shift+Alt+A " block comment
Ctrl+'      " line comment
Ctrl+Alt+a  " Codeium chat
```


## Custom Mappings
```vim

<leader>tr " toggle line numbers
<leader>nh " clear highlights
<leader>+/- " increment/decrementSpecific
```

## Registers
```vim
"ayiw     " yank word to a
"ap       " paste from a
:reg      " view registers
```

## Tips

ciw deletes word and enters insert

vep replaces word preserving register

gv reselects last visual selection

:norm applies commands to multiple lines

* selects all occurrences for multi-cursor

text
