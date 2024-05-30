setopt interactivecomments
bindkey -e

pd=~/projects/myproject
src=$pd/src

cp $BZY_SCRIPT $src/poc/poc-myscript.r
cp $BZY_WF $src/poc/poc-myscript.sh

cp $BZY_QMD $src/poc/reports/poc-myreport.qmd
cp $BZY_WF_QMD $src/poc/reports/poc-myreport.sh

