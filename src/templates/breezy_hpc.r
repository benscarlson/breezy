#!/usr/bin/env Rscript --vanilla

# ==== Input parameters ====

'
Usage:
breezy_hpc.r <dat> <out>  [--db=<db>] [--seed=<seed>] [--parMethod=<parMethod>] [--cores=<cores>] [--mpilogs=<mpilogs>]

Control files:
  ctfs/entity.csv

Parameters:
  dat: path to input csv file. 
  out: path to output directory.

Options:
-d --db=<db> Path to movement database. Defaults to <wd>/data/move.db
-s --seed=<seed>  Random seed.
-p --parMethod=<parMethod>  Either <mpi | mc>. If not passed in, script will run sequentially.
-c --cores=<cores>  The number of cores
-m --mpilogs=<mpilogs> Directory for the mpi log files

' -> doc

if(interactive()) {

  .pd <- here::here()
  .wd <- file.path(.pd,'analysis')
  
  .datPF <- file.path(.wd,'input.csv')
  .dbPF <- file.path(.wd,'data/duck.db')
  .cores <- 7
  .outP <- file.path(.wd,'output')
  .parMethod <- NULL
  .seed <- NULL

} else {

  ag <- docopt::docopt(doc, version = '0.1\n')
  
  .script <-  whereami::thisfile()
  
  .pd <- rprojroot::is_rstudio_project$make_fix_file(.script)()
  .wd <- getwd()
  
  source(file.path(.pd,'src','funs','input_parse.r'))
  
  .datPF <- makePath(ag$dat)
  .dbPF <- makePath(ag$db,'data/duck.db')
  .cores <- parseParam(ag$cores) #TODO: is ag$cores text so I need to parse?
  .mpiLogP <- makePath(ag$mpilogs,'mpilogs')
  .outPF <- makePath(ag$out)
  .parMethod <- ag$parMethod
  .seed <- parseParam(ag$seed)

}

# ==== Setup ====

#---- Initialize Environment ----#

pd <- function(...) file.path(.pd,...)
wd <- function(...) file.path(.wd,...)

if(!is.null(.seed)) {message(paste('Random seed set to',.seed)); set.seed(as.numeric(.seed))}

t0 <- Sys.time()

source(pd('src/startup.r'))

suppressWarnings(
  suppressPackageStartupMessages({
    library(DBI)
    library(iterators)
    library(foreach)
    library(duckdb)
  }))

list.files(pd('src/funs/auto'),full.names=TRUE) %>% walk(source)

#---- Local functions ----
myfunction_qs <- quietly(safely(myfunction))

#---- Local parameters ----
.statusPF <- wd('status.csv')

#---- Files and directories ----#

dir.create(.outP,showWarnings=FALSE,recursive=TRUE)

# Initialize output file
'ent_id,num,minutes' %>% 
  write_lines(.outPF)

#---- Load control files ----#
ents <- read_csv(file.path(.wd,'ctfs/entities.csv')) %>% 
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

message(glue('Running for {nrow(ents)} entities'))

# ==== Perform analysis ====
foreach(i=icount(nrow(niches)),.combine='rbind') %mypar% {
    #i <- 1
    tsTask <- Sys.time()
    ent <- ents[i,]
    
    db <- dbConnect(duckdb(), dbdir=.dbPF, read_only=TRUE)
    invisible(assert_that(length(dbListTables(db))>0))
    
    tsMod <- Sys.time()
    #Do stuff here ....
    
    dbDisconnect(db,shutdown=TRUE)
    
    #example writing to output file
    tibble(ent_id=ent$end_id,
           num=nrow(dat),
           minutes=as.numeric(diffmin(tsMod))) %>% 
      write_csv(.outPF,append=TRUE,na="")
    
    message(glue('{spp$spid} ({i} of {nrow(species)}) is complete in {diffmin(tsEnt)} minutes'))
    
    return(tibble(spid=ent$ent_id,
      task_success=TRUE,
      task_mts=as.numeric(diffmin(tsTask))))
    
  } -> status

status %>% 
  as_tibble(.name_repair = 'minimal') %>%
  rename(status=1) %>% 
  write_csv(.statusPF,na="")

#---- Finalize script ----

message(glue('Script complete in {diffmin(t0)} minutes'))

if(!is.null(.parMethod) && .parMethod=='mpi') { #seems nothing after mpi.quit() is executed, so make sure this is the last code
  closeCluster(cl)
  mpi.quit()
}

