# TODO: see gpta/src/poc/cluc/cluc_hpc_random_50_2.sh for a more integrated way of publishing reports

setopt interactivecomments
bindkey -e

pd=~/projects/myproject
wd=$pd/analysis/main
src=$pd/src
db=$pd/analysis/main/data/database.db
sesnm=main

mkdir -p $wd

cd $wd

qmd=$src/poc/myreport.qmd

fbase=${${qmd##*/}%.qmd} #Get file name without extenstion
out=$wd/reports/$fbase.html

mkdir -p ${out%/*}

quarto render $qmd -P wd:$wd -P sesnm:$sesnm
mv ${qmd%.*}.html $out
open $out

#---- Publish report
proj=myproj

RPT_HOME=~/projects/reports/reports/docs

mkdir $RPT_HOME/$proj

cp $out $RPT_HOME/$proj

rptsrc=~/projects/reports/reports

git -C $rptsrc status
git -C $rptsrc add .
git -C $rptsrc status
git -C $rptsrc commit -am 'add/update reports'
git -C $rptsrc push

echo https://benscarlson.github.io/reports/proj/${out##*/}