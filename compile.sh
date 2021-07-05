#!/bin/bash

source config/settings.sh

# Check command line parameters
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

pushd translations/"$PROJECT"/languages/ > /dev/null || exit

for code in ${LANGS[@]}; do
    path="$code/"

    wp i18n make-json "$path"/ --no-purge
    wp i18n make-json "$path"/plugins/ --no-purge
    wp i18n make-json "$path"/themes/ --no-purge

    find "$path" -name \*.po -print -execdir sh -c 'msgfmt -f -o "$(basename "$0" .po)-'"$code"'.mo" "$0"' '{}' \;
done

# Remove previous compilation
rm -rf ../binaries/

# Create directory structure required later
mkdir -p ../binaries/mu-plugins/

for code in ${LANGS[@]}; do
    pushd > /dev/null "$code/" || exit

    mv wordpress-"$code".mo "$code".mo
    rename -v "s/^wordpress-(.+)$/$code-\$1/" wordpress-*.json

    cp -r --parents $(find -name \*.mo -type f -print) ../../binaries
    cp -r --parents $(find -name \*.json -type f -print) ../../binaries
    rm $(find -name \*.mo -type f -print)
    rm $(find -name \*.json -type f -print)

    popd > /dev/null || exit
done

mv ../binaries/functions-*.mo ../binaries/mu-plugins/

# Create symbolic links
pushd ../binaries/plugins/ > /dev/null || exit

for code in ${LANGS[@]}; do
    if test -f ../mu-plugins/functions-"$code".mo; then
        ln -s ../mu-plugins/functions-"$code".mo agora-functions-"$code".mo
    fi
    if test -f ../mu-plugins/functions-"$code".mo; then
        ln -s ../mu-plugins/functions-"$code".mo common-functions-"$code".mo
    fi
    if test -f bbpress-enable-tinymce-visual-tab-"$code".mo; then
        ln -s bbpress-enable-tinymce-visual-tab-"$code".mo bbp-tinymce-visual-tab-"$code".mo
    fi
    if test -f author-category-"$code".mo; then
        ln -s author-category-"$code".mo author_cat-"$code".mo
    fi
    if test -f buddypress-group-email-subscription-"$code".mo; then
        ln -s buddypress-group-email-subscription-"$code".mo bp-ass-"$code".mo
    fi
    if test -f widget-visibility-without-jetpack-"$code".mo; then
        ln -s widget-visibility-without-jetpack-"$code".mo jetpack-"$code".mo
    fi
    if test -f wp-recaptcha-"$code".mo; then
        ln -s wp-recaptcha-"$code".mo recaptcha-"$code".mo
    fi
    if test -f tabs-responsive-"$code".mo; then
        ln -s tabs-responsive-"$code".mo wpsm_tabs_r-"$code".mo
    fi
    if test -f wordpress-telegram-"$code".mo; then
        ln -s wordpress-telegram-"$code".mo wptelegram-"$code".mo
    fi
done

popd > /dev/null || exit

# Remove incorrect file and replace by the correct one
pushd ../binaries/ > /dev/null || exit
rm ca.mo
mv ca-ca.mo ca.mo
popd > /dev/null || exit

popd > /dev/null || exit

echo -e "\n= DONE. Compiled translations at: translations/$PROJECT/binaries/\n"
