#!/bin/bash

set -e;

if [ $"$*" = "-h" ] || [ $"$*" = "--help" ];
then
    VERSION="v1.0.0";
    SELF=$(basename $0);
    printf "$SELF $VERSION\n";
    printf "Splits a text into lines based on a separator.\n";
    printf "Use: $SELF <separator> <text>\n";
    exit 0;
fi

SEPARATOR=$1;
TEXT="${@:2}";

if [ -z "$SEPARATOR" ] || [ -z "$TEXT" ];
then
    printf "You must pass <separator> and <text> arguments.\n" >> /dev/stderr;
    exit 1;
fi

IFS=$SEPARATOR;
read -ra TEXT_PARTS <<< $TEXT
for TEXT_PART in "${TEXT_PARTS[@]}"; do # access each element of array
    echo $TEXT_PART;
done

exit 0;
