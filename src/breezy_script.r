#!/usr/bin/env Rscript --vanilla
# chmod 744 script_template.r #Use to make executable

#TODO: make a generic "mode" parameter. User can define modes for alternative code pathways
#TODO: check if output directory exists and create it if it does not
#TODO: write output parameters to a database instead of a csv file
#TODO: if writing output to same path as an existing entry in 
# the parameters database (i.e. overwriting), should delete old
# parameter entries.
#TODO: <out> assumes path is subfolder of wd. should have logic for absolute path
#TODO: should source all files in the funs folder
'
Template

Usage:
script_template <out> [-t] [--seed=<seed>]
script_template (-h | --help)

Options:
-h --help     Show this screen.
-v --version     Show version.
-s --seed=<seed>  Random seed. Defaults to 5326 if not passed
-t --test         Indicates script is a test run, will not save output parameters or commit to git
' -> doc

#---- Input Parameters ----#
if(interactive()) {
  library(here)

  .wd <- '~/projects/project_template/analysis'
  .script <- 'src/script_template.r' #Currently executing script
  .seed <- NULL
  .test <- TRUE
  rd <- here
  
  .outPF <- file.path(.wd,'figs/myfig.png')
  
} else {
  library(docopt)
  library(rprojroot)

  ag <- docopt(doc, version = '0.1\n')
  .wd <- getwd()
  .script <-  thisfile()
  .seed <- ag$seed
  .test <- as.logical(ag$test)
  rd <- is_rstudio_project$make_fix_file(.script)
  
  .outPF <- ifelse(isAbsolute(ag$out),ag$out,file.path(.wd,ag$out))
}

#---- Initialize Environment ----#
.seed <- ifelse(is.null(.seed),5326,as.numeric(.seed))

set.seed(.seed)
t0 <- Sys.time()

source(rd('src/startup.r'))

suppressWarnings(
  suppressPackageStartupMessages({
    library(DBI)
    library(RSQLite)
  }))

source(rd('src/funs/breezy_funs.r'))
source(rd('src/funs/themes.r'))
theme_set(theme_eda)

#---- Local parameters ----#
.dbPF <- file.path(.wd,"data/database.db")

#---- Load control files ----#
nsets <- read_csv(file.path(.wd,'ctfs/niche_sets.csv'),col_types=cols()) %>% 
  filter(as.logical(run)) %>% select(-run)
niches <- read_csv(file.path(.wd,'ctfs/niches.csv'),col_types=cols()) %>% 
  filter(as.logical(run)) %>% select(-run) %>%
  inner_join(nsets %>% select(niche_set),by='niche_set')

#---- Initialize database ----#
db <- dbConnect(RSQLite::SQLite(), .dbPF)
invisible(assert_that(length(dbListTables(db))>0))

std <- tbl(db,'study')

#---- Load data ----#
dat0 <- read_csv(file.path(.wd,'obsbg_anno.csv'),col_types=cols())

#---- Perform analysis ----#

dbExecute(db,'PRAGMA foreign_keys=ON')
dbBegin(db)



#---- Save output ---#
dir.create(dirname(.outPF),recursive=TRUE,showWarnings=FALSE)

h=6; w=9
if(fext(.outPF)=='pdf') {
  ggsave(.outPF,plot=p,height=h,width=w,device=cairo_pdf) #save pdf
} else if(fext(.outPF)=='png') {
  ggsave(.outPF,plot=p,height=h,width=w,type='cairo')
}


#---- Finalize script ----#

if(!.test) {
  spsm(library(git2r))
  spsm(library(uuid))
  
  .runid <- UUIDgenerate()
  .parPF <- file.path(.wd,"run_params.csv")
  
  #Update repo and pull out commit sha
  repo <- repository(rd('src'))
  
  rstat <- status(repo)
  if(length(rstat$staged) + 
     length(rstat$unstaged) + 
     length(rstat$untracked) > 0) {
    add(repo,'.')
    commit(repo, glue('script auto update. runid: {.runid}'))
  }
  
  
  .git_sha <- sha(repository_head(repo))
  
  #Save all parameters to csv for reproducibility
  #TODO: write this to a workflow database instead
  saveParams(.parPF)
}

dbCommit(db)
dbDisconnect(db)

message(glue('Script complete in {diffmin(t0)} minutes'))