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

    wp i18n make-json $path/ --no-purge
    wp i18n make-json $path/plugins/ --no-purge
    wp i18n make-json $path/themes/ --no-purge

    find $path -name \*.po -print -execdir sh \
        -c 'msgfmt -f -o "$(basename "$0" .po)-'"$code"'.mo" "$0"' '{}' \;
done

for code in ${LANGS[@]}; do
    pushd $code/
    mv wordpress-$code.mo $code.mo
    rename -v "s/^wordpress-(.+)$/$code-\$1/" wordpress-*.json
    cp -r --parents $(find -name \*.mo -type f -print) ../../binaries
    cp -r --parents $(find -name \*.json -type f -print) ../../binaries
    rm $(find -name \*.mo -type f -print)
    rm $(find -name \*.json -type f -print)
    mkdir ../../binaries/mu-plugins/
    mv ../../binaries/functions-*.mo ../../binaries/mu-plugins/
    popd
done

popd

echo -e "\n= DONE. Compiled translations at: $PROJECT/po/branch\n"
