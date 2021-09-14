#!/usr/bin/env Rscript --vanilla

# ==== Input parameters ====

'
Usage:
breezy_hpc.r <dat> <out>  [--db=<db>] [--sesid=<sesid>] [--seed=<seed>] [--parMethod=<parMethod>] [--cores=<cores>] [--mpilogs=<mpilogs>] [-t] 
breezy_hpc.r (-h | --help)

Control files:
ctfs/individual.csv

Parameters:
dat: path to input csv file. 
out: path to output directory.

Options:
-h --help     Show this screen.
-v --version     Show version.
-d --db=<db> Path to movement database. Defaults to <wd>/data/move.db
-r --sesid=<sesid>  Id that uniquely identifies a script run
-s --seed=<seed>  Random seed. Defaults to 5326 if not passed
-t --test         Indicates script is a test run, will not save output parameters or commit to git
-p --parMethod=<parMethod>  Either <mpi | mc>. If not passed in, script will run sequentially.
-c --cores=<cores>  The number of cores
-m --mpilogs=<mpilogs> Directory for the mpi log files
' -> doc

if(interactive()) {
  library(here)

  .wd <- '~/projects/project_template/analysis'
  .seed <- NULL
  .test <- TRUE

  rd <- here
  
  .sesid <- 'test1'
  
  .datPF <- file.path(.wd,'input.csv')
  .outP <- file.path(.wd,'output')
  .dbPF <- file.path(.wd,'data/mosey.db')
  
  .parMethod <- NULL
  #.cores <- 7
} else {
  library(docopt)
  library(rprojroot)

  ag <- docopt(doc, version = '0.1\n')
  
  .wd <- getwd()
  .script <-  thisfile()
  .seed <- ag$seed
  .test <- as.logical(ag$test)
  rd <- is_rstudio_project$make_fix_file(.script)
  .sesid <- ag$sesid
  .parMethod <- ag$parMethod
  .cores <- ag$cores

  source(rd('src/funs/input_parse.r'))
  
  #.list <- trimws(unlist(strsplit(ag$list,',')))
  .datPF <- makePath(ag$dat)
  .outPF <- makePath(ag$out)
  
  .mpiLogP <- makePath(ifelse(is.null(ag$mpilogs),'mpilogs',ag$mpilogs))
  if(length(ag$db)==0) {
    .dbPF <- file.path(.wd,'data/mosey.db')
  } else {
    .dbPF <- makePath(ag$db)
  }
}

# ==== Setup ====

#---- Initialize Environment ----#

.seed <- ifelse(is.null(.seed),5326,as.numeric(.seed)) 

set.seed(.seed)
t0 <- Sys.time()

source(rd('src/startup.r'))

suppressWarnings(
  suppressPackageStartupMessages({
    library(DBI)
    library(iterators)
    library(foreach)
    library(RSQLite)
  }))

source(rd('src/funs/auto/breezy_funs.r'))

#---- Local parameters ----#

#---- Files and directories ----#

dir.create(.outP,showWarnings=FALSE,recursive=TRUE)

# Initialize output file
# TODO: use tidy evaluation to allow bare column names
c('individual_id','num','minutes') %>% 
  paste(collapse=',') %>% 
  write_lines(.outPF)

#---- Load control files ----#
inds <- read_csv(file.path(.wd,'ctfs/individual.csv'),col_types=cols()) %>% 
  filter(as.logical(run)) %>% select(-run)

#---- Initialize database ----#
invisible(assert_that(file.exists(.dbPF)))

#---- Load data ----#
message('Loading data...')
dat0 <- read_csv(.datPF,col_types=cols()) %>%
  inner_join(inds %>% select(individual_id),by='individual_id')

# ==== Start cluster and register backend ====
if(is.null(.parMethod)) {
  message('No parallel method defined, running sequentially.')
  #foreach package as %do% so it is loaded even if the parallel packages are not
  `%mypar%` <- `%do%`
} else if(.parMethod=='mpi') {
  message('Registering backend doMPI')
  library(doMPI)
  
  dir.create(.mpiLogP,showWarnings=FALSE,recursive=TRUE)
  #start the cluster. number of tasks, etc. are defined by slurm in the init script.
  message('Starting mpi cluster.')
  cl <- startMPIcluster(verbose=TRUE,logdir=.mpiLogP)
  registerDoMPI(cl)
  setRngDoMPI(cl) #set each worker to receive a different stream of random numbers
  
  `%mypar%` <- `%dopar%`
  
} else if(.parMethod=='mc') {
  #.cores <- strtoi(Sys.getenv('SLURM_CPUS_PER_TASK', unset=1)) #for testing on hpc
  message(glue('Registering backend doMC with {.cores} cores'))
  library(doMC)
  RNGkind("L'Ecuyer-CMRG")
  
  registerDoMC(.cores)
  
  `%mypar%` <- `%dopar%`
  
} else {
  stop('Invalid parallel method')
}

# ==== Perform analysis ====
foreach(i=icount(nrow(niches)),.combine='rbind') %mypar% {
    #i <- 1
    tsEnt <- Sys.time()
    ind <- inds[i,]
    

    db <- dbConnect(RSQLite::SQLite(), .dbPF)
    
    invisible(assert_that(length(dbListTables(db))>0))
    
    std <- tbl(db,'study')
    
    #Do stuff here ....
    
    dbDisconnect(db)
    
    #example writing to output file
    tibble(individual_id=ind$individual_id,
           num=nrow(dat),
           minutes=as.numeric(diffmin(tNs))) %>% 
      write_csv(.outPF,append=TRUE,na="")
    
    message(glue('{ind$individual_id} complete in {diffmin(tsEnt)} minutes'))
    return(TRUE)
  } -> status

status %>% 
  as_tibble(.name_repair = 'minimal') %>%
  rename(status=1) %>% 
  write_csv(.statusPF,na="")

# ==== Finalize script ====
if(!.test) {
  suppressWarnings(
    suppressPackageStartupMessages({
      library(git2r)
      library(uuid)
    }))
  
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

message(glue('Script complete in {diffmin(t0)} minutes'))

if(!is.null(.parMethod) && .parMethod=='mpi') { #seems nothing after mpi.quit() is executed, so make sure this is the last code
  closeCluster(cl)
  mpi.quit()
}

