#Non-chatty version of startup. Also does not load theme which requires wd.
message('Running startup script...')
spsm <- suppressPackageStartupMessages

spsm(library(conflicted))
spsm(library(glue))
spsm(library(here)) #usually here is loaded already
#spsm(library(lubridate)) #lubridate has a ton of conflicts with dplyr
spsm(library(tidyverse))
spsm(library(uuid))

options(stringsAsFactors=FALSE)

conflict_prefer('here','here',quiet=TRUE) #Lubridate masks here(), but here() is depredated
conflict_prefer('filter','dplyr',quiet=TRUE)
conflict_prefer('select','dplyr',quiet=TRUE)