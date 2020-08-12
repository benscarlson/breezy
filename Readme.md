---
output:
  pdf_document: default
  html_document: default
---

# Use breezy manually

1) Download breezy repo code to mycoolproject
2) Rename .Rproj file
3) Initialize a git repo inside src
4) Copy breezy_script.r to a new file and start editing it

# Install breezy

```bash
# Set breezy_home locally
breezy_home=~/projects/breezy

# Set breezy_home permanantly
# Save a copy of .bash_profile first
ts=.bash_profile_`date +%Y-%m-%d_%H-%M-%S`
cp ~/.bash_profile ~/${ts}
echo "export BREEZY_HOME=${breezy_home}" >> ~/.bash_profile

#Make project init script executable and add command to path
chmod 744 ${breezy_home}/src/init/breezy.sh
ln -s ${breezy_home}/src/init/breezy.sh ~/bin/breezy #Make sure ~/bin is in path

# Restart shell or source .bash_profile

```

# Use breezy

Initialize a mycoolproject in the directory ~/projects

```bash
breezy ~/projects/mycoolproject

```

# Breezy workflows

* analysis - this is where all output from scripts go. Can make subfolders with different scenarios, slightly different datasets, more recent versions of workflow, etc.
* data - should hold data that is provided to you. Any derived data should generally go into the analysis folder. Data that is shared across many analysis folders can also go into data/derived subfolder
* docs - all non-code/non-data documents. manuscript versions, etc.
* src - all source code for the project. The contents of this folder is the git repo for the project.

* script_template.r - this is the heart of the workflow system. Copy this to workflow or figs directory. See below for more extensive description of script_template.r

# Workflow design

* Script template has a lot of stuff in it. But, as a script matures you almost always end up adding all of these elements. So, why not just start with it? Also, it's much easier to delete code then to write it, so if you know you won't be using something just delete it.

* Script should not perform analysis and also generate figure. Instead, one script should perform the analysis and save results in database (or csv, rdata objects, shp, etc). Second script should load this data and generate the figure.

* In general most scripts start in the poc folder. Figure everything out, then copy the script to the figs or workflow folder. Make this file into an executable script. Remove extraneous analyses, tests, and eda figures that you don't want to save.

* Always run scripts from the analysis directory.

### script_template.r

### Other best practices

* When receiving data, save in data directory as their_data.csv, then save the email in the same folder as their_data_email.pdf


Default working directly is the project dir. So, within code can easily access data using read_csv('data/mydata.csv')

### TODO

* Make bash command to copy template from breezy codebase to working project
* Make rstudio add-in to copy template to working project. https://rstudio.github.io/rstudioaddins/

### Other notes

* Does not make sense to make breezy into an r package.