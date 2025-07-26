test
# grammar
CAPITAL for apply rest of line : A,I,Y
cc repeat for apply to rest of line: cc,yy,dd,
iw inside word: diw/yiw delete inside word/yank inside word
i" inside ": di"
a" including ": ex di"
---
try on this text "this is a stupid text"
---
# Normal mode

## move in Normal Mode
gg move to first line of file
#G move to # line
%  move to matching ([{ when on a matching 
]) move to closing ) when inside 
]% move to closing )]} when inside 
C-f/b move forward/back one screen
C-d/u move forward/back half screen
$ move to end of line

## jumplist
* certain searches and movements are added to jumplist
    * Searching (/ or ?)
    * Jumping to a specific line number (e.g., 10G)
    * Using commands like % (matching parentheses)
    * Moving between files (e.g., gf)

## move the Cursor line (for example to peek above )
C-e/y move cursor line up/down
zz move cursor line to middle
zt move cursor line to top
zb move cursor line to bottom

## delete replace change
d$ delete till end of line
dG delete till endo of file
de delete till endo of word
dip delete this paragraph
di} delete till end of paragraph


cc change whole word
C  change to eol
cip change in paragraph
ci" change in "
ci} change in }

r replace letter
R  replace till ESC

## yanking paste 
yip copy this paragraph
p/P paste before/after
    * if the buffer is a line before/after will paste in previous/next line


## undo redo
u undo
C-r redo

## search replace confirm
%s search in whole current file
%s/ search for poop
    * enter to confirm
    * n/N for next/last

## case switch
g~e toggle case till end of word 
gU$ uppercase till end of line



# nvim in shell
space tr : toggle line numbers
\- : start Oil the file manager
leader nh Clear search highlights

### increment/decrement numbers
leader + Increment number
leader - Decrement number

### window management
leader sv Split window vertically
leader sh Split window horizontally
leader se Make splits equal size
leader sx Close current split
C-w n new buffer in split

### Tab management

leader to Open new tab
leader tx Close current tab
leader tn Go to next tab
leader tp Go to previous tab
leader tf Open current buffer in new tab

surround: https://github.com/kylechui/nvim-surround/wiki/getting-started-for-beginners
ysiwf : surround this word with parenthesis and prompt for function
dsf : delete surrounding function
  ysa”f : surround quote with function




[vim cheat sheet](/vim-cheat.png)

[vi - How do I use vim registers? - Stack Overflow](https://stackoverflow.com/questions/1497958/how-do-i-use-vim-registers) <--- super cool on macros as registers
. : to replay latest
qh : record macro to h
q : stop recording
@h : play macro in h

### visual block mode example
C-v enter visual block, j or k to select lines
S-i to insert before, write -poop-
<esc> to make it happen to all lines.
gv to reselect multi lines and then 
$ to go to end, write something
<esc> to make it happen in all selected lines

## norm:
visual mode highlight som text
:norm A); will add a a parenthesis after each selected line
:norm I print( will add print( before each line
q: history, run older command again
gcc toggle comment line
gc toggle comment

## search
%s/poop searches for poop

## plugin vs code vim surround

y s w” surround line
d s ] delete surrounding ]
c s ] } replace with curly
d i “ delete inside quotes
## deleting
3dd : delete three lines
y3fi : yank from cursor to 3rd i
d/poop : delete to poop
d0 :delete to start of line

ciw delete word and enter insert
diw delete word
diW delete till whitespaces

r replace letter
R replace till ESC
viwp replace this word with contents of reg 0
vep replace this word but now reg has changed

## pasting
1p tp paste from reg 1 in normal mode
ctrl-r 1 to paste from reg 1 in insert mode

## **vscode:**
shift alt a toggle block comment
ctrl ‘ toggle line comment

## vscode commands
toggle indentation to space
refresh extensions
toggle whitespace

## visual mode
v visual mode
V visual line mode
gc toggle comment selected

## yanking
YY yank line
yiw yank word

## navigating

gg : **<<<**beginning of file
G :end of file**>>>**
0 : **b**eginning of line
$ : end of lin**e
I : firs 
% matching parenthesis/brackets
I first non empty
^ last non empty char on ling
C-w hjkl to navigate between windows (also see added shortcut in vscode)
f,F forward backward to char
t,T forward backward to char before char
;,, repeat search forward or backward
{}  backward forward jump paragraph
\* : select other ocurrences of current word
    n, N or enter to navigate
n, N to navigate and ctrl-n if you want to select the occurrence you are on now if you want to edit it, once you have selected all that you want to edit you can edit them all at once

## command line (: in normal mode)

:s/r/t substitute r with t
:%s/r/t substitute first r on every line with t
:nmap show keybindings for normal mode, vmap and so on...
:%s/r/t/g substitute all r on each line with t


# OIL

g. show hidden
?

# NVIM in VSCODE
C-A-a codeium toggle chat 


S-C up/down vs-code multiline 
S-E exit vs-code multiline

## added to user settings json
H,L focus on previous/last tab
Q close tab
C-w v ,| split verticle
C-w s , _ split horizontal


