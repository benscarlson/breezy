# Helper functions for working with hypervolumes

#' Returns union of n hypervolumes given a list of hypervolumes
#' For union operations, recommended distance factor is 3.
unionHvs <- function(hvs,distFact=3) {
  hvs %>% reduce(function(hv1,hv2) {
    hvSet <- hypervolume_set(hv1, hv2, distance.factor=distFact,
                             check.memory=FALSE, verbose=FALSE)
    union <- hvSet@HVList$Union
    union@Name <- 'union'
    return(union)
  }) %>%
    return
}