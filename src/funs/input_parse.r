isAbsolute <- function(path) {
  grepl("^(/|[A-Za-z]:|\\\\|~)", path)
}

# makePath <- function(path,wd=getwd()) {
#   path <- trimws(path)
#   ifelse(isAbsolute(path),path,file.path(wd,path))
# }
#' If the path is relative, prefix with the working directory
#' Allow setting a default relative path if the path argument is NULL
#' If path and default are both null, then return null
makePath <- function(path,default=NULL,wd=getwd()) {
  
  if(is.null(path)) path <- default
  
  if(is.null(path)) return(NULL)
  
  path <- trimws(path)
  ifelse(isAbsolute(path),path,file.path(wd,path))
}

identity_function <- function(x) {
  return(x)
}

#Parses "a,b,c" into a vector
#Reliably returns NULL if the input is NULL
#Can apply f (e.g. as.integer)
#Can't do this after the return b/c NULL is not handled consistently
#e.g. as.integer(NULL) returns integer(0), not NULL
#
#TODO: use parseParam instead of passing in f
parseCSL <- function(val,f=identity_function) {
  if(is.null(val)) {
    return(NULL)
  } else {
    return(f(trimws(unlist(strsplit(val,',')))))
  }
}

#' Return appropriate primitive.
#' If val is NULL, returns default if set, or NULL otherwise.
#' TODO: might need to use bigint
#' TODO: call this parseDataType or similar?
parseParam <- function(val,default=NULL) {
  if(is.null(val)) {
    return(default)
  } else if(grepl("^\\d+$",val)) { #match integer
    return(as.integer(val))
  } else if(grepl("^-?\\d*\\.?\\d+$", val)) { #match numeric
    return(as.numeric(val))
  } else if(grepl('^(TRUE|FALSE)$',val)) { #match logical
    return(as.logical(val))
  } else {
    return(val) #string
  }
}

#' Use when multiple parameters can be passed to a single paramter
#' e.g. with "[--params=<params>]..."
#' Returns named list with each argument parsed to the correct primitive type
#' 
parseMultiParam <- function(params,delim='=') {
  # params <- c('a=1','b=TRUE  ','c= 1.2','z=abc')

  if(is.null(params)) return(NULL)
  
  #base R version
  p <- strsplit(params, delim)
  
  # Extracting names and values from the split list
  names <- sapply(p, `[`, 1)
  values <- sapply(p, `[`, 2)
  
  setNames(values, names) |>
    as.list() |>
    lapply(trimws) |>
    lapply(parseParam)
  
  #tidyverse version
  
  # params %>% 
  #   enframe(name=NULL) %>%
  #   separate_wider_delim(value,delim=delim,names=c('name','value'),too_many='merge') %>%
  #   mutate(across(everything(),trimws)) %>%
  #   deframe %>% 
  #   as.list %>% 
  #   map(parseParam)
}
