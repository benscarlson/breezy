setopt interactivecomments
bindkey -e

pd=~/projects/myproject
wd=$pd/analysis/main
src=$pd/src
db=$pd/analysis/main/data/database.db
sesnm=main

mkdir -p $wd

cd $wd

qmd=$src/reports/myreport.qmd

fbase=${${qmd##*/}%.qmd} #Get file name without extenstion
out=$wd/reports/$fbase.html

mkdir -p ${out%/*}

quarto render $qmd -P wd:$wd -P sesnm:$sesnm
mv ${qmd%.*}.html $out
open $out
