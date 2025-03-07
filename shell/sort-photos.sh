#! /bin/bash

set -e

usage (){
  printf "\n\n usage : sort-photos.sh <path to src files> <path to destination files>\n\n"

}

if [ "$#" -ne 2 ]; then
  usage
  exit 255
fi


src="$1"/*
dest=$2
for file in $src
do
  if [ -f "$file" ] 
    then
    echo "processing file $file"
    filename=$(basename "$file")
    year=`date -r "${file}" "+%Y"`
    month=`date -r "${file}" "+%b"`
    dest_path="${dest}/${year}/${month}/"
    #echo "making path ${dest_path}..."
    `mkdir -p ${dest_path} `
    mv_cmd="mv -n ${file} ${dest}/${year}/${month}/${filename}"
    `${mv_cmd}`
  fi

done

