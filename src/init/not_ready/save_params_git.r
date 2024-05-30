
# if(!.test) {
#   library(git2r)
#   library(uuid)
#   
#   .runid <- UUIDgenerate()
#   .parPF <- file.path(.wd,"run_params.csv")
#   
#   #Update repo and pull out commit sha
#   repo <- repository(rd('src'))
#   
#   rstat <- status(repo)
#   if(length(rstat$staged) + 
#      length(rstat$unstaged) + 
#      length(rstat$untracked) > 0) {
#     add(repo,'.')
#     commit(repo, glue('script auto update. runid: {.runid}'))
#   }
#   
#   
#   .git_sha <- sha(repository_head(repo))
#   
#   #Save all parameters to csv for reproducibility
#   #TODO: write this to a workflow database instead
#   saveParams(.parPF)
# }