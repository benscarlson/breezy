
options(stringsAsFactors=FALSE)
options(dplyr.summarise.inform = FALSE) #https://www.tidyverse.org/blog/2020/05/dplyr-1-0-0-last-minute-additions/
options(tidyverse.quiet = TRUE) #https://rstats-tips.net/2020/07/31/get-rid-of-info-of-dplyr-when-grouping-summarise-regrouping-output-by-species-override-with-groups-argument/

suppressWarnings(
suppressPackageStartupMessages({
  library(assertthat)
  library(conflicted)
  library(fasttime)
  library(glue)
  #library(here)
  library(lubridate)
  library(tictoc)
  library(tidyverse)
  library(uuid)
}))

options(readr.show_col_types = FALSE)

# Several common packages have conflicts with dplyr filter() and select()
conflict_prefer('filter','dplyr',quiet=TRUE)
conflict_prefer('select','dplyr',quiet=TRUE)