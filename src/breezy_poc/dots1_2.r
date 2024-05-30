#!/usr/bin/env Rscript --vanilla

# This script implements the breezy philosophy: github.com/benscarlson/breezy

# ==== Breezy setup ====

'
Usage:
dots1.r [--params=<params>]...

Options:
-p --params=<params>  Passed to function
' -> doc

#---- Input Parameters ----
if(interactive()) {
  
  pd <- here::here()
  # .wd <- file.path(.pd,'analysis')
  
  .pars <- list(a=1,b=1.2,c=TRUE,z='abc')
  
} else {

  ag <- docopt::docopt(doc)
  
  .script <-  whereami::thisfile()
  
  .pd <- rprojroot::is_rstudio_project$make_fix_file(.script)()
  # .wd <- getwd()

  source(file.path(.pd,'src','funs','input_parse.r'))
  
  .pars <- parseMultiParam(ag$params)

}

pd <- function(...) file.path(.pd,...)

source(pd('src','startup.r'))

myfun <- function(a,b,...) {
  print(a)
  print(b)

  subfun(...)
}

subfun <- function(z,c) {
  print(z)
  print(c)
}

rlang::exec('myfun',!!!.pars)

