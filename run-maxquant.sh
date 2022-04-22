#!/usr/bin/bash env
set -euo pipefail
trap 's=$?; echo >&2 "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR

Help()
{
   # Display Help
   echo "Run MaxQuant Analysis"
   echo
   echo "Syntax: run-maxquant.sh [-m|v|r|h]"
   echo "options:"
   echo "m     MaxQuant Filename without ending .xml - e.g. mqpar_210830"
   echo "p     Project Name - e.g. 20220406_FH_TR"
   echo "v     Version: new or old"
   echo "r     no. of runs"
   echo "h     Print this help"
   echo
}





version="new"
runs=1

while getopts hm:v:r:p: flag
do
    case "${flag}" in
        m) filename=${OPTARG};;
        v) version=${OPTARG};;
        r) runs=${OPTARG};;
        p) projname=${OPTARG};;
        h) # display Help
           Help
           exit;;
    esac
done


########################
# settings
#########################

echo "#####################################" | tee -a log.txt
echo "settings" | tee -a log.txt
echo "#####################################" | tee -a log.txt

echo "Filename: $filename" | tee log.txt
echo "Project name: $projname" | tee -a log.txt
echo "Version: $version" | tee -a log.txt
echo "No. of runs: $runs" | tee -a log.txt

#######################
# check directories
#######################
echo "#####################################" | tee -a log.txt
echo "check directories" | tee -a log.txt
echo "#####################################" | tee -a log.txt
folder=/proj/proteomics/
if [ -d "$folder$projname" ]; then
  # Take action if $DIR exists. #
  cd $folder
  echo "Project Folder {$folder$projname} exists. Continue" | tee -a log.txt
  mkdir -p ./$projname/data ./$projname/mqpar ./$projname/results
else
  echo "Project Folder {$folder$projname} doesn't exists. Aborting..." | tee -a log.txt
  exit 1
fi



#########################
# activate maxquant
#########################
echo "#####################################" | tee -a log.txt
echo "activate maxquant" | tee -a log.txt
echo "#####################################" | tee -a log.txt
if [ $version = "new" ]
then
	echo "new version of maxquant is used"
	conda activate maxquant2
	echo "Current conda environment is $CONDA_DEFAULT_ENV" | tee -a log.txt

else
	echo "old version of maxquant is used"
	conda activate maxquant
	echo "Current conda environment is $CONDA_DEFAULT_ENV" | tee -a log.txt
fi

###############################
#check and disable net core
###############################
echo "#####################################" | tee -a log.txt
echo "check and disable net core" | tee -a log.txt
echo "#####################################" | tee -a log.txt

search="<useDotNetCore>True"
replace="<useDotNetCore>False"

if [[ $search != "" && $replace != "" ]]; then
sed -i "s/$search/$replace/" ./mqpar_tmp/$filename.xml
echo "<useDotNetCore> was set to False" | tee -a log.txt
fi

###############################
# re-name path file paths
###############################
#<path-to-current-xmlfile> --changeFolder <path-to-new-xmlfile> <path-to-fasta-folder> <path-to-rawfile-folder>

echo "#####################################" | tee -a log.txt
echo "re-naming paths in $filename.xml" | tee -a log.txt
echo "#####################################" | tee -a log.txt

maxquant ./mqpar_tmp/$filename.xml --changeFolder ./$projname/mqpar/$filename.xml ./fasta ./$projname/data | tee -a log.txt

#re-name fixed combine folder
sed -i "/<fixedCombinedFolder>/c\   <fixedCombinedFolder>\/proj\/proteomics\/$projname\/results\/test<\/fixedCombinedFolder>" ./$projname/mqpar/$filename.xml
echo "re-naming of combined folder sucessful" | tee -a log.txt


###############################
# start maxquant
###############################
echo "#####################################" | tee -a log.txt
echo "run maxquant" | tee -a log.txt
echo "#####################################" | tee -a log.txt
maxquant ./$projname/mqpar/$filename.xml | tee -a log.txt


###############################
# clean up
###############################
echo "#####################################" | tee -a log.txt
echo "clean up" | tee -a log.txt
echo "#####################################" | tee -a log.txt


#move logfile
mv ./log.txt ./$projname 

#remove mqpar_temp file
