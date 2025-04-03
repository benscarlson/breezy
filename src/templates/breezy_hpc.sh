setopt interactivecomments
bindkey -e

proj=my_project
pd=~/projects/$proj
ses=analysis_session
wd=$pd/analysis/$ses
src=$pd/src

mkdir -p $wd
mkdir -p $wd/data
mkdir -p $wd/ctfs

cd $wd

$src/poc/script.r

