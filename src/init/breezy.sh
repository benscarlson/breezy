#!/usr/bin/env bash

#TODO: Option to sync with github

PATH=$PATH:../..
eval "$(docopts -h - : "$@" <<EOF
Usage: breezy [options] <argv>...
First arg is the path and name of the project.
Examples:
  breezy ~/projects/mycoolproject
  breezy projects/mycoolproject
  breezy mycoolproject

Options:
      --help     Show help options.
      --version  Print program version.
----
breezy 0.1

EOF
)"

#----
#---- Set up variables
#----

to=${argv[0]}
pn=${to##*/} #project name

#----
#---- Copy project files
#----

echo "Copying project files"

mkdir -p $to #TODO: maybe rsync can do this

# Copy folder structure and template code to new project
# Ignores the init folder which contains this script
rsync -rP --exclude=${BREEZY_HOME}/src/init ${BREEZY_HOME}/* $to
rm $to/Readme.md #Remove Readme for breezy repo

#Rename project file
mv $to/breezy.Rproj $to/${pn}.Rproj
#Copy .Rprofile
cp ${BREEZY_HOME}/.Rprofile $to
#Copy project readme file
#cp ${BREEZY_HOME}/src/init/Readme.md $to/src/Readme.md

#----
#---- Git repo
#----

echo "Initialize git repo"

#Need to figure out how to do this w/o changing directory
wd=`pwd`

cd $to/src

git init
git add .
git commit -am 'initialize repo'

cd $wd