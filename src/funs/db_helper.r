checkRows <- function(rows,x,db) {
  if(rows != x) {
    message('Rows did not match. Rolling back.') 
    dbRollback(db); stop('Stopping script')
  }
}