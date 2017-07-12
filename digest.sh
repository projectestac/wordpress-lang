#!/bin/bash

source config/settings.sh

if [ $# -ne 1 ]; then
    echo "Usage: bash $0 <project>"
    exit 1
fi

PROJECT=$1

source config/settings-$PROJECT.sh

for lang in ${LANGS[@]}; do
    basepath=translations/$PROJECT/languages/$lang
    files=`find $basepath -depth -type f -name \*.po`
    
    msgcat --use-first $files | msgattrib --translated --no-fuzzy \
        --no-obsolete > translations/$PROJECT/memories/$lang.po
done

echo "Done"