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
  
  .pars <- c('a=1','b=TRUE','c=1.2','z=abc')
  
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

print(.pars)

class(.pars$a)
class(.pars$b)
class(.pars$c)
class(.pars$z)


# myfun <- function(a,b,...) {
#   print(a)
#   print(b)
#   
#   #print(list(...))
#   #rlang::exec('subfun',!!!list(...))
#   subfun(...)
# }
# 
# subfun <- function(x) {
#   print(x)
# }
# 
# args <- list(b=2,c=3,x=4)
# 
# rlang::exec('myfun2',12,!!!args)

