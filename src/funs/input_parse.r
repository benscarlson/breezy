isAbsolute <- function(path) {
  grepl("^(/|[A-Za-z]:|\\\\|~)", path)
}

makePath <- function(path,wd=getwd()) {
  path <- trimws(path)
  ifelse(isAbsolute(path),path,file.path(wd,path))
}