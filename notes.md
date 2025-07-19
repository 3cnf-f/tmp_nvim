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

