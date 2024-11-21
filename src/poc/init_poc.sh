setopt interactivecomments
bindkey -e

pd=~/projects/myproject
src=$pd/src

#==== Templates ====

env | grep BZY

cp $BZY_SCRIPT $src/poc/myscript.r
cp $BZY_WF $src/poc/myscript.sh

cp $BZY_QMD $src/poc/myreport.qmd
cp $BZY_QMD_SUB $src/poc/myreport_sub.qmd
cp $BZY_WF_QMD $src/poc/myreport.sh

#====