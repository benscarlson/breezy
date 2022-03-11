
#-- parameters
wd=~/projects/project_template/analysis
src=~/projects/project_template/src

cd $wd

#chmod 744 $src/figs/hero_figure.r #Use to make executable

$src/figs/hero_figure.r figs/hero_v4.pdf
$src/figs/hero_figure.r figs/hero_v4.png