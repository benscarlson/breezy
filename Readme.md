# What is breezy?

Breezy is a philosophy and associated code base for creating scientific workflows. Scientists spend a considerable amount of time building code-based workflows for their analyses, yet there is almost no formal instruction or even information on the best way to build these workflows. Best practices from the information-technology industry, mostly focused on application coding, provide some guidance, but many of these ideas do not apply or are even unhelpful for scientific workflows. Although there are many existing workflow frameworks, these can require significant time and knowledge investment, often hide their actions behind sets of opaque functions, and are better suited for large collaborative projects. 

# Why breezy?

Breezy is a different approach to building lightweight scientific workflows. It provides structure for organizing code and data, templates that provide commonly used scaffolding code and allow easy conversion to bash scripts, and a command-line driven approach to workflow execution that significantly enhances reproducibility. In addition, in recognition that most effort goes into the development of scripts, breezy is built around the full development lifecycle, with many features that allow scientists to seamlessly promote code from a hacky proof-of-concept to a formal analysis script. This includes features that allow streamlined development for HPC scripts using a seven-step development lifecycle.

# The breezy philosophy

Many useful and important best-practices from the IT industry and application development are relevant to the design of scientific workflows (use of configuration files, loose coupling of code, etc.). Breezy adopts many of these practices. However, there are some key differences in how application and workflow code is used. In application development, coders are encouraged to write small, general functions (e.g. the DRY principle) that are rigorously unit tested. This is because application code is released in cycles, and once released a function might be executed billions of times by millions of users (think of some core sub-routine in MacOS). In contrast, in small scientific workflows, a scientists might spent days or weeks developing an analysis script, culminating in a final run with the full dataset and final parameters. If the the results look good, this code might never be executed again!

In addition, developing general functions that span across multiple projects or scripts can erode usability. As time goes on, it is often the case that you need to make small tweaks to your functions or add functionality. But in doing so, these changes often break older script that rely on the functions. This is the purpose of unit tests--to rigorously test all functionality to make sure nothing is broken. But is it worthwhile to retest your entire code base, even for projects that are years old and code that likely will never be executed again?

Instead of small general functions, breezy instead is designed around relatively small, independent scripts. Each script should be isoclated from code changes in other scripts, except where scripts share inputs or outputs. The core scaffolding code is duplicated within each script. This allows researchers the flexibility to change any aspect of a script without fear of impacting other functionality. Although breezy does have some general functions, these are very small and the function code is not shared across projects. User-defined functions also make sense at times, but again these functions should not be shared across projects, but rather a project should receive its own copy of the function code.

## Many small scripts

A core component of breezy is to separate your analysis into relatively small scripts that can be executed from the command line. A single bash workflow script (often executed manually) calls scripts in the correct order and defines input parameters.

Scripts should generally peform a single operation and save the results to a csv file, an rds object, or a database. For example, in a traditional R script you might perform complex data management actions such as subsetting based on some criteria, transforming variables, joining with other datasets, etc. The script then runs models on the resulting data, and finally outputs some figures. But what happens at some later point when you want to change your models? Or update the figure? You need to work through the entire script, even parts that you don't need to touch. Under breezy, you would split this script into three (or maybe even more) seperate breezy scripts.

* filter_and_merge.r
* models.r
* figure.r

Each script should save its results to disk, and be passed (via input parameters) to the next script, with the sequence of execution handled by a bash workflow script. This design is much more flexible. For example, if you wanted to create a new figure based on the model outputs, you could just create a new script (figure2.r) and specify the model results as inputs.

## Focused operations over many entities, rather than complex operations over single entities.

Given the traditional R script described above, say you had to run the analysis over a really large dataset. It might be tempting to make this work by running the entire script over a single entity, one entity at a time (or perhaps even in parallel). This is a common approach but not ideal because the script is still complex, difficult to debug, and does not take advantage of R's rich functionality for data manipulation through packages such as dplyr or data.table. Intead, it is much better to run all entities through each step in the workflow. If you need to paralellize, do parallization within a script, not across all scripts in the workflow. This makes scripts easier to debug, since you are doing relatively simple operations (even if over many entities). This design also lets you parallelize over less complex operations, which simplifies debugging. For example, in the breezy workflow above, you might only need to parallize over the model estimation. In this case you only need to debug parallel code in models.r, instead of over the entire workflow. This is especially beneficial when using high performance cluster.

## Control files

A common practice in R is to load an entire dataset into memory and then loop through the dataset performing some operation on each entity in the dataset. But often it is necessary to run the script on a subset of the entities, so this approach requires making changes to the code for each desired subset. Breezy makes use of a special type of configuration file called a control file. A control file contains a list of all entities, and a 'run' column. A breezy script will only run the script for indicated entities. In the example below, entities are individuals. The script will perform operations for animal_1 and animal_2, but not animal_3. In addition to providing more fine-grained control, aiding script development and processing of subsets, the control file can also provide a permanent record of which entities were part of a particular analysis. Finally, use of control files sets up the script to use a database instead of a csv file. 

| individual | run |
|------------|-----|
| animal_1 | 1 |
| animal_2 | 1 |
| animal_3 | 0 |


## Other features

* Input parameters - The breezy template uses docopt, which is a human readable system for defining and managing input parameters. Just write your help text and docopt will parse it and make parameters available to you in the R environment.
* Path management - seamlessly transition from interactive development to command line driven execution

# Use breezy manually

1) Download breezy repo code to mycoolproject
2) Rename .Rproj file
3) Initialize a git repo inside src
4) Copy breezy_script.r to a new file and start editing it

# Install breezy

```bash

# Set breezy_home locally
breezy_home=~/projects/breezy

# Download repo code


# Set breezy_home permanantly
# Save a backup of .bash_profile first
ts=.bash_profile_`date +%Y-%m-%d_%H-%M-%S`
cp ~/.bash_profile ~/${ts}
echo "export BREEZY_HOME=${breezy_home}" >> ~/.bash_profile
echo 'export BREEZY_SCRIPT=${BREEZY_HOME}/src/breezy_script.r' >> ~/.bash_profile

#Make project init script executable and add command to path
chmod 744 ${breezy_home}/src/init/breezy.sh
ln -s ${breezy_home}/src/init/breezy.sh ~/bin/breezy #Make sure ~/bin is in path

#Do the same for breezy_refresh
chmod 744 ${breezy_home}/src/init/breezy_refresh.sh
ln -s ${breezy_home}/src/init/breezy_refresh.sh ~/bin/breezy_refresh #Make sure ~/bin is in path

# Restart shell or source .bash_profile

```

# Use breezy

Initialize a mycoolproject in the directory ~/projects

```bash
breezy ~/projects/mycoolproject

```

Refresh the project with the latest core breezy files. This just updates four files: breezy_script.r, breezy_funs.r, startup.r, and themes.r

```bash
breezy ~/projects/mycoolproject

```

