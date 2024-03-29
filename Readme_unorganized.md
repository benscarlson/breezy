# Breezy folder structure

* analysis - this is where all output from scripts go. Can make subfolders with different scenarios, slightly different datasets, more recent versions of workflow, etc.
* data - should hold data that is provided to you. Any derived data should generally go into the analysis folder. Data that is shared across many analysis folders can also go into data/derived subfolder
* docs - all non-code/non-data documents. manuscript versions, etc.
* src - all source code for the project. The contents of this folder is the git repo for the project.
  * poc - Analysis usually starts in the proof of concept folder. Any scripts in this folder should not be part the public release of code. This gives you freedom to try out different approaches, write code you are not proud of, etc. Once the analysis matures and becomes part of the formal workflow, copy or move the script to the workflow folder.
  * workflow - This folder should contain the scripts that make up the formal workflow for your project
    * workflow.sh - This is the bash script that contains the full list of commands to execute your project

# Breezy code
* breezy_script.r - this is the heart of the workflow system. Copy this script and start making edits. See below for more extensive description of script_template.r
* breezy_hpc.r
* breezy_report.r

# Development lifecycle

The breezy framework allows you to seamlessly move from unorganized proof-of-concept code to mature workflow scripts. The following steps are generally used.

* Hack away in interactive mode on a breezy template in the poc directory
* After a certain point, the script matures. Can run it as a script 

# Workflow design

* The breezy script has a lot template code. As a script matures, I almost always end up adding all of these elements. So, why not just start with it? Also, it's much easier to delete code then to write it, so if you know you won't be using something just delete it.

* Script should not perform analysis and also generate figure. Instead, one script should perform the analysis and save results in database (or csv, rdata objects, shp, etc). Second script should load this data and generate the figure.

* In general most scripts start in the poc folder. Figure everything out, then copy the script to the figs or workflow folder. Make this file into an executable script. Remove extraneous analyses, tests, and eda figures that you don't want to save.

* Always run scripts from the analysis directory.

### breezy_template.r

TBD 

### Best practices

#### Workflow

* A different scenario should be run out of a different analysis folder. Make a new set of control files, workflow script, and use a different session id.

* When receiving data, save in data directory as their_data.csv, then save the email in the same folder as their_data_email.pdf

#### Interactive development

Default working directly is the project dir. So, within code can easily access data using read_csv('data/mydata.csv')

Should have a main workflow scripts within wf_scripts. This should be a small number of scripts (maybe just one) that will run the analysis. 
Don't include poc code in these workflow scripts. Make a seperate script in the poc folder that has all the code for running experimental and testing scripts.

I usually have a small number of workflow scripts for the initial submission, then one script for each revision. e.g. wf_main.sh, wf_rev1.sh, wf_rev2.sh

In genreal, when starting a new script, process, etc, make a folder in poc to hold the scripts and a folder in analysis to hold the results. This code and results is temporary. The code (if it becomes part of your main workflow) will transition to the src folder and final results should go into your main analysis folder.

### TODO

* breezy command should have subcommands. e.g. breezy init mycoolproject.
* make a breezy refresh mycoolproject. This copies latest versions of breezy_script.r, breezy_funs.r, themes.r, startup.r
* breezy.sh should delete the init folder after copying
* Make rstudio add-in to copy template to working project. https://rstudio.github.io/rstudioaddins/
* take the misc function files out of funs and move them to a different project

### Other notes

* Does not make sense to make breezy into an r package.