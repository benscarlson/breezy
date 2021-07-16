#!/usr/bin/env Rscript --vanilla

# ==== Input parameters ====

'
Usage:
breezy_hpc.r <dat> <out> [--sesid=<sesid>] [--seed=<seed>] [--parMethod=<parMethod>] [--cores=<cores>] [--mpilogs=<mpilogs>] [-t] 
breezy_hpc.r (-h | --help)

Control files:
ctfs/niches.csv
ctfs/niche_set.csv

Parameters:
dat: path to csv file. 
  should have niche_set, niche_name, and one column for each niche axis.
  should be a scaled dataset.
out: path to output directory

Options:
-h --help     Show this screen.
-v --version     Show version.
-r --sesid=<sesid>  Id that uniquely identifies a script run
-s --seed=<seed>  Random seed. Defaults to 5326 if not passed
-t --test         Indicates script is a test run, will not save output parameters or commit to git
-p --parMethod=<parMethod>  Either <mpi | mc>. If not passed in, script will run sequentially.
-c --cores=<cores>  The number of cores
-m --mpilogs=<mpilogs> Directory for the mpi log files
' -> doc

if(interactive()) {
  library(here)

  .wd <- '~/projects/ms1/analysis/rev2/dist_env_test'
  .seed <- NULL
  .test <- TRUE

  rd <- here
  
  .sesid <- 'test1'
  
  .datPF <- '~/projects/ms1/data/derived/obs_anno_100_full.csv'
  .outP <- file.path(.wd,.sesid)
  
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
    library(RSQLite)
  }))

source(rd('src/funs/auto/breezy_funs.r'))

#---- Local parameters ----#
.dbPF <- file.path(.wd,"data/database.db")

#---- Files and directories ----#

dir.create(.outP,showWarnings=FALSE,recursive=TRUE)

# Set up output file
tibble(ses_id=character(), 
       rep=numeric(),
       niche_set=character(),
       niche_name=character(),
       niche_vol=numeric(),
       minutes=numeric()) %>% write_csv(.outPF)

#---- Load control files ----#
nsets <- read_csv(file.path(.wd,'ctfs/niche_sets.csv'),col_types=cols()) %>% 
  filter(as.logical(run)) %>% select(-run)
niches <- read_csv(file.path(.wd,'ctfs/niches.csv'),col_types=cols()) %>% 
  filter(as.logical(run)) %>% select(-run) %>%
  inner_join(nsets %>% select(niche_set),by='niche_set')

#---- Initialize database ----#
invisible(assert_that(file.exists(.dbPF)))

db <- dbConnect(RSQLite::SQLite(), .dbPF)

invisible(assert_that(length(dbListTables(db))>0))

std <- tbl(db,'study')

#---- Load data ----#
message('Loading data...')
dat0 <- read_csv(.datPF,col_types=cols()) %>%
  inner_join(niches %>% select(niche_set,niche_name),by='niche_name')

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
    niche <- niches[i,]
    
    #Do stuff here ....
    
    #example writing to output file
    tibble(ses_id=.sesid,
           rep=j,
           niche_set=nset,
           niche_set_vol=get_volume(hvNset),
           minutes=as.numeric(diffmin(tNs))) %>% 
      write_csv(.outPF,append=TRUE)
    
    message(glue('{niche$niche_name} complete in {diffmin(tsEnt)} minutes'))
    return(TRUE)
  } -> status

status %>% 
  as_tibble(.name_repair = 'minimal') %>%
  rename(status=1) %>% 
  write_csv(.statusPF)

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

