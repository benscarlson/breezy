toPoly <- function(dat) {
  require(sf)
  
  bind_rows(dat,dat[1,]) %>% #close polygon
    as.matrix %>%
    list %>%
    st_polygon %>%
    return
}