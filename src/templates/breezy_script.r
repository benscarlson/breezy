#!/usr/bin/env Rscript --vanilla

# This script implements the breezy philosophy: github.com/benscarlson/breezy

# ==== Breezy setup ====

'
Template

Usage:
breezy_script.r <sesnm> <dat> <out> [--db=<db>] [--psesnm=<psesnm>] [--seed=<seed>] [-b]

Control files:
  ctfs/entity.csv

Parameters:
  dat: path to input csv file. 
  out: path to output directory.
  sesnm: session name.

Options:
-d --db=<db> Path to the database. Defaults to <wd>/data/database.db
-p --psesnm=<psesnm>  Parent session name
-s --seed=<seed>  Random seed.
-b --rollback   Rollback transaction if set to true.
' -> doc

#---- Input Parameters ----
if(interactive()) {
  
  .pd <- here::here()
  .wd <- file.path(.pd,'analysis')
  
  .datPF <- file.path(.wd,'data/dat.csv')
  .dbPF <- file.path(.wd,'data/database.db')
  .outPF <- file.path(.wd,'figs/myfig.pdf')
  .psesnm <- 'main'
  .seed <- NULL
  .sesnm <- 'test1'
  .rollback <- FALSE
  
} else {

  ag <- docopt::docopt(doc)
  
  .script <-  whereami::thisfile()
  
  .pd <- rprojroot::is_rstudio_project$make_fix_file(.script)()
  .wd <- getwd()

  source(file.path(.pd,'src','funs','input_parse.r'))
  
  .datPF <- makePath(ag$dat)
  .dbPF <- makePath(ag$db,'data/duck.db')
  .outPF <- makePath(ag$out)
  .psesnm <- ag$psesnm
  .seed <- ag$seed #don't set to numeric here. TODO: use parseCSL
  .sesnm <- ag$sesnm
  .rollback <- as.logical(ag$rollback) #TODO use parseCSL

}

#---- Initialize Environment ----

pd <- function(...) file.path(.pd,...)
wd <- function(...) file.path(.wd,...)

t0 <- Sys.time()

source(pd('src/startup.r'))

suppressWarnings(
  suppressPackageStartupMessages({
    #library(DBI)
    library(duckdb)
  }))

#Source all files in the auto load funs directory
list.files(pd('src/funs/auto'),full.names=TRUE) %>% walk(source)
source(pd('src/funs/themes.r'))

theme_set(theme_eda)

#---- Local functions ----

#---- Local parameters ----

#---- Files and folders ----

#---- Load control files ----#
studies <- read_csv(wd('ctfs/study.csv')) %>%
  filter(as.logical(run)) %>% select(-run)

inds <- read_csv(wd('ctfs/individual.csv')) %>% 
  filter(as.logical(run)) %>% select(-run)

#---- Initialize database ----#
invisible(assert_that(file.exists(.dbPF)))
db <- dbConnect(duckdb(), dbdir=.dbPF, read_only=TRUE)
invisible(assert_that(length(dbListTables(db))>0))

styTb <- tbl(db,'study')

#---- Load data ----
message('Loading data...')

psesid <- getSesId(.psesnm,'table name',db)

hvLevels <- enum('hv_level',db)

dat0 <- read_csv(.datPF,col_types=cols()) %>%
  inner_join(inds %>% select(individual_id),by='individual_id')

dat <- 'select * from table' %>%
  glue_sql(.con=db) %>% dbGetQuery(db,.) %>% tibble


#---- Perform analysis ----

#Do stuff here...
p <- dat %>% ggplot(aes(x=x,y=y)) + geom_point; if(interactive()) {print(p)}

#---- Save output ----

#---- Saving to the database ----#

invisible(dbExecute(db,'PRAGMA foreign_keys=ON'))
dbBegin(db)

sesid <- addSession(.sesnm,psesid,'population',db)

#---- Appending rows ----#
dat %>%
  dbAppendTable(db,'table',.) %>%
  checkRows(nrow(dat),db)

#---- Updating rows ----#
rs <- dbSendStatement(db, 'update table set col2 = $col2 where id=$id')

dbBind(rs,dat)

rs %>% 
  dbGetRowsAffected %>%
  checkRows(nrow(dat),db)

dbClearResult(rs)

#---- Saving a csv or other file ----#
message(glue('Saving to {.outPF}'))

dir.create(dirname(.outPF),recursive=TRUE,showWarnings=FALSE)

datout %>% write_csv(.outPF,na="")

#---- Saving a figure ----#
h=6; w=9; units='in'
  
if(fext(.outPF)=='pdf') {
  ggsave(.outPF,plot=p,height=h,width=w,device=cairo_pdf,units=units) #save pdf
} else if(fext(.outPF)=='png') {
  ggsave(.outPF,plot=p,width=w,height=h,type='cairo',units=units)
} else if(fext(.outPF)=='eps') {
  ggsave(.outPF,plot=p,width=w,height=h,device=cairo_ps,units=units,bg='transparent')
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

dbDisconnect(db,shutdown=TRUE)

message(glue('Script complete in {diffmin(t0)} minutes'))