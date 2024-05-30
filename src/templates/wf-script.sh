setopt interactivecomments
bindkey -e

pd=~/projects/my_project
wd=$pd/analysis
src=$pd/src
db=~/projects/ms2/analysis/main/data/mosey.db

sesnm=main

mkdir -p $wd

cd $wd

$src/poc/script.r $sesnm --db $db -b

