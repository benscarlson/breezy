#!/usr/bin/env Rscript --vanilla
# chmod 744 breezy_report-knit.r #Use to make executable

# This script implements the breezy philosophy: github.com/benscarlson/breezy

# ==== Breezy setup ====

'
Sets up input parameters and knits rnw file. Can specify pdf output.
This is a template file, each rnw file should have its own customized knit_breezy.r script
Code in the rnw file has access to all variables set in this script.

Usage:
breezy_report-knit.r <sesid> <out> [--db=<db>] [--entity=<entity>] [--seed=<seed>] [-t]
breezy_report-knit.r (-h | --help)

Control files:
  ctfs/study.csv
  ctfs/individual.csv

Parameters:
  sesid: the session id
  out: path to output directory.

Options:
-h --help     Show this screen.
-v --version     Show version.
-d --db=<db> Path to movement database. Defaults to <wd>/data/mosey.db
-e --entity=<entity>  Either <study|individual> Defines control file that will constrain processing. Defaults to study
-s --seed=<seed>  Random seed. Defaults to 5326 if not passed
-t --test         Indicates script is a test run, will not save output parameters or commit to git
' -> doc

#---- Input Parameters ----#
if(interactive()) {
  library(here)

  .wd <- '~/projects/ms3/analysis/full_workflow_poc/test6'
  .script <- file.path(.wd,'src/templates/report/breezy_report-knit.r')
  .seed <- NULL
  .test <- TRUE
  rd <- here::here
  
  #Required parameters
  .sesid <- 'full_wf'
  .outP <- file.path(.wd,'reports/breezy_report')
  
  .dbPF <- '~/projects/ms3/analysis/full_workflow_poc/data/mosey.db'
  .entity <- 'individual'

} else {
  library(docopt)
  library(rprojroot)

  ag <- docopt(doc, version = '0.1\n')
  .wd <- getwd()
  .script <-  thisfile()
  .seed <- ag$seed #don't set to numeric here
  .rollback <- as.logical(ag$rollback)
  .test <- as.logical(ag$test)
  rd <- is_rstudio_project$make_fix_file(.script)
  
  source(rd('src/funs/input_parse.r'))
  
  #Required parameters
  .outP <- makePath(ag$out)
  .sesid <- ag$sesid
  
  #Options
  #.list <- trimws(unlist(strsplit(ag$list,',')))
  .dbPF <- makePath(ifelse(length(ag$db)!=0, ag$db,'data/mosey.db'))
  .entity <- ifelse(is.null(ag$entity),'study',ag$entity)
  
}

#---- Initialize Environment ----#
if(!is.null(.seed)) {message(paste('Random seed set to',.seed)); set.seed(as.numeric(.seed))}

t0 <- Sys.time()

source(rd('src/startup.r'))

suppressWarnings(
  suppressPackageStartupMessages({
    library(Cairo)
    library(DBI)
    library(knitr)
    library(RSQLite)
  }))

#Source all files in the auto load funs directory
list.files(rd('src/funs/auto'),full.names=TRUE) %>% walk(source)
source(rd('src/funs/escapeForLatex.r'))

theme_set(theme_eda)

#---- Local parameters ----#
#Figure out various report componet names and paths. The parameter .script contains the path to the rnw file
#pattern is: <report>-knit.r, <report>.rnw, <report>-sub.rnw
#we have the first script, need to come up with the others
reportP <- dirname(.script)
reportBase <- sub('\\-knit\\.r$','', basename(.script), ignore.case=TRUE)
reportFN <- glue('{reportBase}.rnw')
reportSubFN <- glue('{reportBase}-sub.rnw') #The subreport file name

#---- Load control files ----#
studies <- read_csv(file.path(.wd,'ctfs/study.csv')) %>%
  filter(as.logical(run)) %>% select(-run)

if(.entity=='individual') {
  #Load inds and constrain by study control file.
  inds <- read_csv(file.path(.wd,'ctfs/individual.csv')) %>%
    filter(as.logical(run)) %>% select(-run) %>%
    inner_join(studies %>% select(study_id),by='study_id')
  
  #Now need to constrain studies by the selected individuals
  studies <- studies %>% filter(study_id %in% unique(inds$study_id))
}

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

#-- Generate Report

message('Generating report...')
#have to setwd to the directory of the report for knit to work correctly
#TODO: do this all within trycatch so that I can set wd back if process fails
setwd(reportP)
dir.create(.outP,recursive=TRUE,showWarnings=FALSE)

#Uncomment to make one report per study
# for(i in 1:nrow(studies)) {
#   #i <- 1
#   study <- studies[i,]
#   
#   studyName <- styTb %>% filter(study_id==!!study$study_id) %>% select(study_name) %>% as_tibble %>% as.character
#   message(glue('Processing {studyName} (study id: {study$study_id})'))
  
  pdfPF <- knitr::knit2pdf(
    input=reportFN,
    output=glue('{reportBase}.tex'),
    quiet=TRUE
  )
  
  #---- Save output ---#
  outPF <- file.path(.outP,glue('{reportBase}.pdf'))
  #outPF <- file.path(.outP,'{studyName}.pdf') #Use with study loop
  
  message(glue('Saving to {outPF}'))
  
  copied <- file.copy(pdfPF, outPF, overwrite=TRUE)
  
  #----Clean up ---# 
  message("Cleaning up.")
  invisible(file.remove(file.path(reportP,glue('{reportBase}.tex'))))
  invisible(file.remove(pdfPF))
  invisible(unlink(file.path(reportP,'figure'), recursive = TRUE))
#}

setwd(.wd)

dbDisconnect(db)

message(glue('Script complete in {diffmin(t0)} minutes'))