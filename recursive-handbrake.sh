#!/bin/sh
# Script by Alexandre Esser (github.com/liyali)
# Encode multiple video file at once using HandBrake

usage()
{
cat <<EOF
usage: sh $0 options

This script run Handbrake recusrively in a "-d" directory with "-o" options for "-e" extensions

OPTIONS:
   -h      Show this message
   -d      Base directory to search for video
   -f      Output format (mp4/mkv)
   -o      Handbrake options
   -e      Extensions to match (case insensitive)
   -v      Verbose

EXAMPLE:
./handbrake.sh -d "./Photos/Misc" -f mp4 -v -o "--optimize --encoder x264 --quality 24" -e avi 3gp mov mp4 mpeg mpg wmv m4v
EOF
}

# Text color variables
txtund=$(tput sgr 0 1)          # Underline
txtbld=$(tput bold)             # Bold
bldred=${txtbld}$(tput setaf 1) #  red
bldblu=${txtbld}$(tput setaf 4) #  blue
bldwht=${txtbld}$(tput setaf 7) #  white
txtrst=$(tput sgr0)             # Reset

directory="."                   # default folder 
bkp_extension="bkp"             # default extension for backup files (input files are renamed once converted)

# cli options
format=
options=
extensions=
verbose=
while getopts “hd:f:o:e:v” OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         d)
             directory=$OPTARG
             ;;
         f)
             format=$OPTARG
             ;;
         o)
             options=$OPTARG
             ;;
         e)
             extensions=$OPTARG
             ;;
         v)
             verbose=1
             ;;
         ?)
             usage
             exit
             ;;
     esac
done

if [[ -z ${options} ]] || [[ -z ${extensions} ]] || [[ -z ${format} ]]
then
     usage
     exit 1
fi

# loop through additional filetypes and append
for (( i=0; i<7; i++ )); # Skip first args
do
  shift
done

# set find command options
types='-iname "*.'$1'"'
shift

while [ $# -gt 0 ]
do
  types=${types}' -o -iname "*.'$1'"'
  shift
done

# set the IFS (Internal Field Separator) variable so that it splits 
# fields by tab and newline and don't threat space as a filed separator
oldifs=${ifs}
IFS=$'\t\n'

# read all file name into an array
inputs=($(eval "find '"${directory}"' "${types}))

# restore it 
IFS=${oldifs}
 
# get length of an array
len=${#inputs[@]}

# verbose mode enabled
if [[ ${verbose} == 1 ]]; then
  echo "Handbrake options: $(tput setaf 3)"${options}"$(tput sgr0)"
  sleep 1
  echo "Video output format: $(tput setaf 3)"${format}"$(tput sgr0)"
  sleep 1
  echo "Generated find command: $(tput setaf 3)find '"${directory}"' "${types}"$(tput sgr0)"
  sleep 1
  echo "Number of files to convert: $(tput setaf 3)"${len}"$(tput sgr0)"
  sleep 1
fi

# prepare verbose command for HandBrake
if [[ ${verbose} == 1 ]]; then
  verbose="-v"
else
  verbose=""
fi
# use for loop read all filenames
for (( i=0; i<${len}; i++ ));
do

  format_lc=$(echo ${format} | awk '{print tolower($0)}'); # format to lower
  format_uc=$(echo ${format} | awk '{print toupper($0)}'); # format to upper
  if [[ ${inputs[$i]} == ${inputs[$i]%.*}"."${format_lc} || ${inputs[$i]} == ${inputs[$i]%.*}"."${format_uc} ]]; then
    output=${inputs[$i]%.*}"-optimized."${format}
  else
    output=${inputs[$i]%.*}"."${format}
  fi

  echo
  echo "$(tput setaf 1)Start encoding "${inputs[$i]}"$(tput sgr0)"
  sleep 1
  echo "Command executed: $(tput setaf 4)handbrake --input "${inputs[$i]}" --output "${output}" --format "${format}" "${verbose}" "${options}"$(tput sgr0)"
  sleep 1
  eval handbrake -i '${inputs[$i]}' -o '${output}' -f ${format} ${verbose} ${options}
  if [[ $? == 0 ]]; then
    echo "$(tput setaf 1)End encoding "${output}"$(tput sgr0)"
    sleep 1
    mv ${inputs[$i]} ${inputs[$i]}.${bkp_extension}
    echo "Renaming $(tput setaf 3)"${inputs[$i]}"$(tput sgr0) to $(tput setaf 3)"${inputs[$i]}"."${bkp_extension}"$(tput sgr0)"
    sleep 1
    echo "$(tput setaf 3)"$((${len}-${i}-1))" video(s) left to convert$(tput sgr0)"
    sleep 1
  fi
  echo
  #sleep 10m # used to give a rest to your computer between each conversion =)
done