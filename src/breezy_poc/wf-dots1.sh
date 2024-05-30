setopt interactivecomments
bindkey -e

pd=~/projects/breezy
#wd=$pd/analysis/main
src=$pd/src
#db=$wd/data/database.db

#mkdir -p $wd

#cd $wd

$src/breezy_poc/dots1_1.r -p "a=1" -p "b=1.2" -p "c=TRUE" -p "z=abc"


$src/breezy_poc/dots1_2.r -p "a=1" -p "b=1.2" -p "c=TRUE" -p "z=abc"
