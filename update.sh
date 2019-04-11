#!/bin/bash

source config/settings.sh


# -- Obtain command line parameters --------------------------------------------

if [ $# -lt 2 ]; then
    echo "Usage: bash $0 <project> <git-branch> [version]"
    exit 1
fi

if [ ! -e "config/settings-$1.sh" ]; then
    echo "Project settings not found"
    exit 1
fi

source config/settings-$1.sh

PROJECT=$1
BRANCH=$2
VERSION=$3
WP_CONTENT=${SRC}wp-content

declare -a PLUGINS=()
declare -a THEMES=()


# -- Create a subfolder for the project and change to it -----------------------

mkdir -p output/$PROJECT
pushd output/$PROJECT > /dev/null


# -- Create the required folder structure --------------------------------------

echo -e "= Creating folders"

rm -f -R pot
rm -f -R po

mkdir -p pot/plugins
mkdir -p pot/themes
mkdir -p branch

for code in ${LANGS[@]}; do
    mkdir -p po/upstream/$code/plugins
    mkdir -p po/upstream/$code/themes
    mkdir -p po/branch/$code/plugins
    mkdir -p po/branch/$code/themes
    mkdir -p po/merge/$code/plugins
    mkdir -p po/merge/$code/themes
    mkdir -p po/master/$code/plugins
    mkdir -p po/master/$code/themes
done


# -- Clone the localization tools an the repositories --------------------------

echo -e "\n= Cloning branch: $BRANCH"

pushd branch > /dev/null
git clone -q --recursive $WORDPRESS_URL --branch $BRANCH .
git checkout -q --force $BRANCH
git submodule update -q --init --recursive --rebase --force
popd > /dev/null

rm -f src
ln -s branch/$SRC src


# -- Obtain the WordPress version to translate ---------------------------------

if [ -z $VERSION ]; then
    pushd src > /dev/null
    VERSION=`wp core version | sed -E "s/([0-9]+\.[0-9]+\.)[0-9]+/\1x/"`
    echo -e "\n= Detected version: ${VERSION}"
    popd > /dev/null
else
    echo -e "\n= Version set to: ${VERSION}"
fi


# -- Obtain the list of installed plugins and themes ---------------------------

pushd branch/$WP_CONTENT/plugins/ > /dev/null

for name in *; do
    if [[ -d $name ]]; then
        PLUGINS+=($name)
    fi
done

popd > /dev/null

pushd branch/$WP_CONTENT/themes/ > /dev/null

for name in *; do
    if [[ -d $name ]]; then
        THEMES+=($name)
    fi
done

popd > /dev/null


# -- Copy master translations --------------------------------------------------

echo -e "\n= Copying translations from master"
cp -nr ../../translations/$PROJECT/languages/. po/master/


# -- Download the available upstream translations ------------------------------

echo -e "\n= Downloading upstream translations"

for lang in ${LANGS[@]}; do
    code=`expr match "$lang" '\([a-z]*\)'`
    out_path=po/upstream/$lang

    wget -q $TRANSLATE_URL/wp/$VERSION/$code/$EXPORT_PATH \
         -O $out_path/wordpress.po

    wget -q $TRANSLATE_URL/wp/$VERSION/cc/$code/$EXPORT_PATH \
         -O $out_path/continents-cities.po

    wget -q $TRANSLATE_URL/wp/$VERSION/admin/$code/$EXPORT_PATH \
         -O $out_path/admin.po

    wget -q $TRANSLATE_URL/wp/$VERSION/admin/network/$code/$EXPORT_PATH \
         -O $out_path/admin-network.po

    for name in ${PLUGINS[@]}; do
        wget -q $TRANSLATE_URL/wp-plugins/$name/stable/$code/$EXPORT_PATH \
             -O $out_path/plugins/$name.po || rm -f $out_path/plugins/$name.po
    done

    for name in ${THEMES[@]}; do
        wget -q $TRANSLATE_URL/wp-themes/$name/$code/$EXPORT_PATH \
             -O $out_path/themes/$name.po || rm -f $out_path/themes/$name.po
    done
done


# -- Sort upstream translations ------------------------------------------------

echo -e "\n= Sorting upstream translations"

files=`find po/upstream -type f -name \*.po`

for path in ${files[@]}; do
    msgcat --sort-output $path --output-file=$path
done


# -- Sort the master branch translations ---------------------------------------

echo -e "\n= Sorting translations from master branch"

files=`find po/master -type f -name \*.po`

for path in ${files[@]}; do
    msgcat --sort-output $path --output-file=$path
done


# -- Generate the .pot templates from the source code --------------------------

echo -e "\n= Creating templates"

wp i18n make-pot branch/$SRC/ \
        pot/wordpress.pot \
        --include="*, wp-includes/*, wp-includes/customize/*, wp-includes/rest-api/*, wp-includes/widgets/*, wp-includes/IXR/*" \
        --exclude="wp-admin/*, wp-content/*" \
        --ignore-domain

wp i18n make-pot branch/$SRC/ \
        pot/admin-network.pot \
        --include="wp-admin/includes/class-wp-ms-*.php, wp-admin/includes/network.php, wp-admin/network.php, wp-admin/network/*" \
        --ignore-domain

wp i18n make-pot branch/$SRC/ \
        pot/admin.pot \
        --include="wp-admin/*, wp-admin/includes/*" \
        --exclude="wp-admin/includes/class-wp-ms-*.php, wp-admin/includes/network.php, wp-admin/network.php, wp-admin/network/*" \
        --ignore-domain

wp i18n make-pot branch/$SRC/ \
        pot/continents-cities.pot \
        --include="wp-admin/includes/continents-cities.php" \
        --ignore-domain

wp i18n make-pot branch/$WP_CONTENT/mu-plugins/. \
        pot/functions.pot \
        --include="*, common/*" \
        --ignore-domain

for name in ${PLUGINS[@]}; do
    wp i18n make-pot branch/$WP_CONTENT/plugins/$name/ \
         pot/plugins/$name.pot
done

for name in ${THEMES[@]}; do
    wp i18n make-pot branch/$WP_CONTENT/themes/$name/ \
        pot/themes/$name.pot
done


# -- Merge master and upstream translations ------------------------------------

echo -e "\n= Merging master and upstream translations"

files=`find po/master -type f -name \*.po`

for path in ${files[@]}; do
    msgcat --use-first --sort-output \
        --output-file=po/merge/${path#po/master/} \
        $path po/upstream/${path#po/master/} > /dev/null

    cp -n $path po/merge/${path#po/master/}

    cp -n po/upstream/${path#po/master/} \
          po/merge/${path#po/master/}
done


# -- Merge the translations with the templates ---------------------------------

echo -e "\n= Merging translations"

files=`find po/merge -type f -name \*.po`

for path in ${files[@]}; do
    branch_path=po/branch/${path#po/merge/}

    msgmerge --quiet --sort-output --output-file=$branch_path \
        $path pot/${path#*/*/*/}t > /dev/null

    msgattrib --no-obsolete --output-file=$branch_path \
        $branch_path
done


# -- Merge the translations with the templates ---------------------------------

echo -e "\n= Copying missing upstream translations"

files=`find po/upstream -type f -name \*.po`
cp -r -n po/upstream/* po/branch/


# -- Done ----------------------------------------------------------------------

popd > /dev/null
echo -e "\n= DONE. Updated translations at: $PROJECT/po/branch\n"
