#!/bin/bash

set -e;

if [ $"$*" = "-h" ] || [ $"$*" = "--help" ];
then
    VERSION="v1.0.0";
    SELF=$(basename $0);
    printf "$SELF $VERSION\n";
    printf "Removes white space from the edges of each text.\n";
    printf "Use: $SELF [text1] [text2] [text3...]\n";
    exit 0;
fi

TEXT="$*";

if [ -z "$TEXT" ];
then
    echo "";
else
    echo "$TEXT" | xargs;
fi

exit 0;
