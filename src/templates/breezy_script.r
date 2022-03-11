#!/usr/bin/env Rscript --vanilla

# This script implements the breezy philosophy: github.com/benscarlson/breezy

# ==== Breezy setup ====

'
Template

Usage:
breezy_script.r <dat> <out> [--db=<db>] [--seed=<seed>] [-b]
breezy_script.r (-h | --help)

Control files:
  ctfs/study.csv
  ctfs/individual.csv

Parameters:
  dat: path to input csv file. 
  out: path to output directory.

Options:
-h --help     Show this screen.
-v --version     Show version.
-d --db=<db> Path to movement database. Defaults to <wd>/data/mosey.db
-s --seed=<seed>  Random seed. Defaults to 5326 if not passed
-b --rollback   Rollback transaction if set to true.
' -> doc

#---- Input Parameters ----#
if(interactive()) {
  library(here)

  .wd <- '~/projects/project_template/analysis'
  .seed <- NULL
  .rollback <- TRUE
  rd <- here::here
  
  .datPF <- file.path(.wd,'data/dat.csv')
  .dbPF <- file.path(.wd,'data/mosey.db')
  .outPF <- file.path(.wd,'figs/myfig.pdf')
} else {
  library(docopt)
  library(rprojroot)

  ag <- docopt(doc, version = '0.1\n')
  .wd <- getwd()
  .script <-  thisfile()
  .seed <- ag$seed #don't set to numeric here
  .rollback <- as.logical(ag$rollback)
  rd <- is_rstudio_project$make_fix_file(.script)
  
  source(rd('src/funs/input_parse.r'))
  
  #.list <- trimws(unlist(strsplit(ag$list,',')))
  .datPF <- makePath(ag$dat)
  .outPF <- makePath(ag$out)
  .dbPF <- makePath(ifelse(length(ag$db)!=0,ag$db,'data/mosey.db'))
}

#---- Initialize Environment ----#
if(!is.null(.seed)) {message(paste('Random seed set to',.seed)); set.seed(as.numeric(.seed))}

t0 <- Sys.time()

source(rd('src/startup.r'))

suppressWarnings(
  suppressPackageStartupMessages({
    library(DBI)
    library(RSQLite)
  }))

#Source all files in the auto load funs directory
list.files(rd('src/funs/auto'),full.names=TRUE) %>% walk(source)

theme_set(theme_eda)

#---- Local parameters ----#

#---- Load control files ----#
studies <- read_csv(file.path(.wd,'ctfs/study.csv'),col_types=cols()) %>%
  filter(as.logical(run)) %>% select(-run)

inds <- read_csv(file.path(.wd,'ctfs/individual.csv'),col_types=cols()) %>% 
  filter(as.logical(run)) %>% select(-run)

#---- Initialize database ----#
invisible(assert_that(file.exists(.dbPF)))
db <- dbConnect(RSQLite::SQLite(), .dbPF)
invisible(assert_that(length(dbListTables(db))>0))

styTb <- tbl(db,'study')

#---- Load data ----#
message('Loading data...')
dat0 <- read_csv(.datPF,col_types=cols()) %>%
  inner_join(inds %>% select(individual_id),by='individual_id')

#====

#---- Perform analysis ----#

#Do stuff here...
p <- dat %>% ggplot(aes(x=x,y=y)) + geom_point; if(interactive()) {print(p)}

#---- Save output ---#

#---- Saving to the database ----#

invisible(dbExecute(db,'PRAGMA foreign_keys=ON'))
dbBegin(db)

rows <- dat %>%
  dbAppendTable(db,'table',.)

if(rows=!nrow(dat)) {
  message('Rows did not match. Rolling back.'); dbRollback(db)
  stop('Stopping script')
}

#---- Saving a csv or other file ----#
message(glue('Saving to {.outPF}'))

dir.create(dirname(.outPF),recursive=TRUE,showWarnings=FALSE)

datout %>% write_csv(.outPF,na="")

#---- Saving a figure ----#
h=6; w=9
if(fext(.outPF)=='pdf') {
  ggsave(.outPF,plot=p,height=h,width=w,device=cairo_pdf) #save pdf
} else if(fext(.outPF)=='png') {
  ggsave(.outPF,plot=p,height=h,width=w,type='cairo')
}

#---- Finalize script ----#

#-- Close transaction
if(.rollback) {
  message('Rolling back transaction because this is a test run.')
  dbRollback(db)
} else {
  message('Comitting transaction.')
  dbCommit(db)
}

dbDisconnect(db)

# if(!.test) {
#   library(git2r)
#   library(uuid)
#   
#   .runid <- UUIDgenerate()
#   .parPF <- file.path(.wd,"run_params.csv")
#   
#   #Update repo and pull out commit sha
#   repo <- repository(rd('src'))
#   
#   rstat <- status(repo)
#   if(length(rstat$staged) + 
#      length(rstat$unstaged) + 
#      length(rstat$untracked) > 0) {
#     add(repo,'.')
#     commit(repo, glue('script auto update. runid: {.runid}'))
#   }
#   
#   
#   .git_sha <- sha(repository_head(repo))
#   
#   #Save all parameters to csv for reproducibility
#   #TODO: write this to a workflow database instead
#   saveParams(.parPF)
# }

message(glue('Script complete in {diffmin(t0)} minutes'))