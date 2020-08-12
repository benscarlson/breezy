#this code is taken from ggplot: https://github.com/tidyverse/ggplot2/blob/master/R/stat-ellipse.R
#this is how ggplot calculates a 95% ellipse
#result is a dataframe of x y coordinates that can be plotted using geom_path
ellipsedf <- function(dat) {
  level <- 0.95
  segments <- 51
  dfn <- 2
  dfd <- nrow(dat) - 1
  
  v <- stats::cov.wt(dat)
  
  shape <- v$cov
  center <- v$center
  chol_decomp <- chol(shape)
  radius <- sqrt(dfn * stats::qf(level, dfn, dfd))
  
  angles <- (0:segments) * 2 * pi/segments
  unit.circle <- cbind(cos(angles), sin(angles))
  ellipse <- t(center + radius * t(unit.circle %*% chol_decomp))
  
  return(as.data.frame(ellipse))
}