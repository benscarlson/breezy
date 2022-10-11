getSesId <- function(sesnm,tbnm,db) {
  sesid <- 'select ses_id from session
    where ses_name in ({sesnm*}) and table_name={tbnm}' %>%
    glue_sql(.con=db) %>% dbGetQuery(db,.) %>%
    pull(ses_id)
  
  if(length(sesid)==0) {
    return(NULL)
  } else {
    return(sesid)
  }
}

addSession <- function(sesnm, psesid, tbnm, db) {
  
  rows <- tibble(pses_id=psesid,ses_name=sesnm,table_name=tbnm) %>%
    dbAppendTable(db,'session',.)
  
  assert_that(rows==1)
  
  "select last_insert_rowid() as id" %>%
    dbGetQuery(db,.) %>% as.integer %>% return
}

z <- tibble(x=c(1,NULL),y=c(2,2))

#' Adds attributes to a session
#' x is a vector of variable names
#' If variable points to a vector, the values are collapsed into a single string
#' If variable is null, it is not added as an attribute
# TODO: Could use tidy evaluation to pass in bare var names
addSesAttr <- function(x,sesid,db) {
  #x <- c('.npts','.envs'); sesid <- 30
  dat <- enframe(x,name=NULL,value='var') %>%
    mutate(
      ses_id=sesid,
      attr_name=gsub('^\\.','',var),
      attr_value=map_chr(var,~{
        val <- get(.x)
        ifelse(is.null(val),
               NA,
               paste(as.character(val),collapse=','))
      })) %>%
    filter(!is.na(attr_value)) %>%
    select(ses_id,attr_name,attr_value) 
  
  if(nrow(dat) > 0) {
    rows <- dat %>%
      dbAppendTable(db, 'ses_attr',.)
    
    if(rows != nrow(dat)) {
      message('Rows did not match. Rolling back.')
      dbRollback(db)
      stop('Stopping script')
    }
  }
}
