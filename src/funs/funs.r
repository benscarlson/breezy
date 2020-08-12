
#' @example 
#' t1 <- Sys.time()
#' diffmin(t1)
diffmin <- function(t,t2=Sys.time()) round(difftime(t2, t, unit = "min"),2)

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