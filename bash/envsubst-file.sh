#!/bin/bash

set -e;

if [ $"$*" = "-h" ] || [ $"$*" = "--help" ];
then
    VERSION="v1.0.0";
    SELF=$(basename $0);
    printf "$SELF $VERSION\n";
    printf "Replaces the name of environment variables in a file with their values.\n";
    printf "Use: $SELF <input file> <output file>\n";
    exit 0;
fi

FILE_IN=$1;
FILE_OUT=$2;

if [ -z "$FILE_IN" ] || [ -z "$FILE_OUT" ];
then
    printf "You must pass <input file> and <output file> arguments.\n" >> /dev/stderr;
    exit 1;
fi

if [ ! -r "$FILE_IN" ];
then
    printf "The file <input file> ($FILE_IN) cannot be read.\n" >> /dev/stderr;
    exit 1;
fi

if [ -e "$FILE_IN" ] && [ ! -w "$FILE_IN" ];
then
    printf "The file <output file> ($FILE_OUT) cannot be write.\n" >> /dev/stderr;
    exit 1;
fi

if [ -z "$(command -v envsubst)" ];
then
    printf "Program envsubst is not present.\n" >> /dev/stderr;
    exit 1;
fi

printf "Replacing envs from $FILE_IN to $FILE_OUT.\n";

DEFINED_ENVS=$(printf '${%s} ' $(env | cut -d= -f1));

envsubst "$DEFINED_ENVS" < "$FILE_IN" > "$FILE_OUT";

exit 0;
