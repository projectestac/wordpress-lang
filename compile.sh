#!/bin/bash

source config/settings.sh


# -- Obtain command line parameters --------------------------------------------

if [ $# -ne 1 ]; then
    echo "Usage: bash $0 <project>"
    exit 1
fi

if [ ! -e "config/settings-$1.sh" ]; then
    echo "Project settings not found"
    exit 1
fi

source config/settings-$1.sh

PROJECT=$1

pushd translations/$PROJECT/languages/

for code in ${LANGS[@]}; do
    path="$code/"
    find $path -name \*.po -print -execdir sh \
        -c 'msgfmt -f -o "$(basename "$0" .po)-'"$code"'.mo" "$0"' '{}' \;
done

for code in ${LANGS[@]}; do
    pushd $code/
    cp -r --parents $(find -name \*.mo -type f -print) ../../binaries
    popd
done

popd

echo -e "\n= DONE. Compiled translations at: $PROJECT/po/branch\n"
