#----
#---- These functions are used by breezy_script.r 
#----

#' @example 
#' t1 <- Sys.time()
#' diffmin(t1)
diffmin <- function(t,t2=Sys.time()) round(difftime(t2, t, unit = "min"),2)

#' Convert standard string formatted date to POSIXct Format: 2015-01-01T13:00:51Z
as_timestamp <- function(x) as.POSIXct(x, format='%Y-%m-%dT%H:%M:%S', tz='UTC')

fext <- function(filePath){ 
  ex <- strsplit(basename(filePath), split="\\.")[[1]]
  return(ex[length(ex)])
}

#'Saves parameters for script run from global environment to csv
saveParams <- function(parPF) {
  ls(all.names=TRUE,pattern='^\\.',envir=.GlobalEnv) %>%
    enframe(name=NULL,value='var') %>% 
    filter(!var %in% c('.Random.seed','.runid','.script','.parPF')) %>% #
    mutate(
      script=get('.script'),
      runid=get('.runid'),
      ts=strftime(Sys.time(),format='%Y-%m-%d %T', usetz=TRUE),
      value=map_chr(var,~{toString(get(.))})) %>%
    select(script,runid,ts,var,value) %>%
    arrange(var) %>%
    write_csv(parPF,append=file.exists(parPF))
}