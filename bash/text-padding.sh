#!/bin/bash

set -e;

if [ $"$*" = "-h" ] || [ $"$*" = "--help" ];
then
    VERSION="v1.0.0";
    SELF=$(basename $0);
    printf "$SELF $VERSION\n";
    printf "Insert a space at the edge of the text.\n";
    printf "Use: $SELF <padding> [text]\n";
    printf "To insert on the left <padding> must be negative, to insert on the right it must be positive.\n";
    exit 0;
fi

LENGTH="$1";
TEXT="${@:2}";

REGEX_IS_INTEGER="^[+-]?[0-9]+$";
if [[ ! $LENGTH =~ $REGEX_IS_INTEGER ]];
then
   printf "The <padding> value must be a integer number.\n";
   exit 1;
fi

if [ "${LENGTH:0:1}" = "-" ];
then
    LEFT=true;
    LENGTH="${LENGTH:1}";
else
    LEFT=false;
fi

if [ $LEFT = true ];
then
    MASK="%${LENGTH}s";
else
    MASK="%-${LENGTH}s";
fi
printf "$MASK\n" $TEXT;

exit 0;
