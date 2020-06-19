#!/bin/bash

set -e;

if [ $"$*" = "-h" ] || [ $"$*" = "--help" ];
then
    VERSION="v1.0.0";
    SELF=$(basename $0);
    printf "$SELF $VERSION\n";
    printf "Replaces the name of environment variables in a lot of files with their values.\n";
    printf "Use: $SELF <files suffix> <input directory> <output directory>\n";
    exit 0;
fi

FILES_SUFFIX=$1;
DIR_IN=$2;
DIR_OUT=$3;
DIR_SOURCE=$(pwd);

if [ -z "$FILES_SUFFIX" ] || [ -z "$DIR_IN" ] || [ -z "$DIR_OUT" ];
then
    printf "You must pass <files suffix>, <input directory> and <output directory> arguments.\n" >> /dev/stderr;
    exit 1;
fi

if [ ! -d "$DIR_IN" ];
then
    printf "The <input directory> ($DIR_IN) is not a directory.\n" >> /dev/stderr;
    exit 1;
fi

if [ ! -d "$DIR_OUT" ] && [ -e "$DIR_OUT" ];
then
    printf "The <input directory> ($DIR_OUT) exists as a file.\n" >> /dev/stderr;
    exit 1;
fi

mkdir -p $DIR_OUT;

DEFINED_ENVS=$(printf '${%s} ' $(env | cut -d= -f1));

# TODO: Não usar ls. Usar grep
cd $DIR_IN
for FILE in $(ls -1 | grep -E $FILES_SUFFIX\$);
do
    cd $DIR_SOURCE;

    FILE_WITHOUT_SUFFIX=$(echo $FILE | sed -e  "s/$FILES_SUFFIX//")
    FILE_IN=$(realpath $DIR_IN/$FILE);
    FILE_OUT=$(realpath $DIR_OUT/$FILE_WITHOUT_SUFFIX);

    printf "Replacing envs from $FILE_IN to $FILE_OUT\n";

    envsubst "$DEFINED_ENVS" < "$FILE_IN" > "$FILE_OUT";
done;

exit 0;
