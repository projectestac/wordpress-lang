#!/bin/bash

# -- Configuration for XTEC Blocs ----------------------------------------------

# List of language codes to translate
declare -a LANGS=('ca' 'es_ES')

# GIT repository for the WordPress instance
WORDPRESS_URL=https://github.com/projectestac/xtecblocs.git

# WordPress source folder on the repository
SRC=src/