#!/usr/bin/env bash

#TODO: Option to sync with github

PATH=$PATH:../..
eval "$(docopts -h - : "$@" <<EOF
Usage: breezy_refresh [options] <argv>...
Refreshes core breezy files from breezy code base.
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

echo "Copying core breezy files"

cp ${BREEZY_HOME}/src/breezy_script.r $to/src/breezy_script.r
cp ${BREEZY_HOME}/src/funs/breezy_funs.r $to/src/funs/breezy_funs.r
cp ${BREEZY_HOME}/src/funs/themes.r $to/src/funs/themes.r
cp ${BREEZY_HOME}/src/startup.r $to/src/startup.r